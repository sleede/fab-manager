"""Private, bounded migration primitives; no application backend or third-party package."""
import contextlib
import decimal
import hashlib
import http.client
import ipaddress
import json
import os
from pathlib import Path
import shutil
import socket
import sqlite3
import ssl
import time
import urllib.parse
import uuid


class Blocked(RuntimeError):
    pass


class HTTPFailure(Blocked):
    def __init__(self, status, body):
        self.status, self.body = status, body
        super().__init__("Elasticsearch HTTP %s: %s" % (status, canonical(body)[:600]))


def decode(value):
    return json.loads(value, parse_float=decimal.Decimal,
                      parse_constant=lambda _: (_ for _ in ()).throw(Blocked('Non-finite JSON number')))


def canonical(value):
    if value is None:
        return 'null'
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, (int, decimal.Decimal)):
        number = decimal.Decimal(value)
        if not number.is_finite():
            raise Blocked('Non-finite number')
        if abs(number.as_tuple().exponent) > 10000 or len(number.as_tuple().digits) > 10000:
            raise Blocked('Numeric representation exceeds the explicit canonicalization bound')
        # Do not normalize with Decimal's default 28-digit context (which rounds).
        result = format(number, 'f')
        if '.' in result:
            result = result.rstrip('0').rstrip('.')
        return ('-0.0' if number.is_signed() else '0') if number == 0 else result
    if isinstance(value, float):
        return canonical(decimal.Decimal(str(value)))
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list):
        return '[' + ','.join(canonical(item) for item in value) + ']'
    if isinstance(value, dict):
        return '{' + ','.join(canonical(key) + ':' + canonical(value[key]) for key in sorted(value)) + '}'
    raise Blocked('Unsupported JSON value')


def digest(value):
    return hashlib.sha256(canonical(value).encode()).hexdigest()


def segment(value):
    return urllib.parse.quote(value, safe='')


def free_space(path, needed):
    if shutil.disk_usage(path).free < needed:
        raise Blocked('Insufficient local space; nothing may be discarded to continue')


def atomic(path, value):
    path = Path(path)
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    temporary = path.with_name(path.name + '.tmp')
    with temporary.open('w', encoding='utf-8') as stream:
        os.chmod(temporary, 0o600)
        stream.write(canonical(value) + '\n')
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)
    directory = os.open(path.parent, os.O_RDONLY)
    try:
        os.fsync(directory)
    finally:
        os.close(directory)


class HTTP:
    def __init__(self, options, address=None):
        parsed = urllib.parse.urlsplit(options['url'])
        if parsed.scheme not in ('http', 'https') or parsed.username or parsed.password or parsed.path not in ('', '/') or parsed.query or parsed.fragment:
            raise Blocked('Endpoint must be a fixed HTTP(S) origin without embedded credentials')
        if parsed.scheme == 'http' and not options.get('allow_private_http'):
            raise Blocked('Plain HTTP requires explicit private-network approval')
        self.host, self.port, self.scheme = parsed.hostname, parsed.port or (443 if parsed.scheme == 'https' else 80), parsed.scheme
        self.address = address or socket.gethostbyname(self.host)
        if not ipaddress.ip_address(self.address).is_private:
            raise Blocked('Migration endpoints must use private addresses')
        self.context = ssl.create_default_context(cafile=options.get('ca_file'))
        self.headers = {'Content-Type': 'application/json', 'Accept': 'application/json', 'Host': self.host}
        if options.get('password_env'):
            import base64
            secret = os.environ[options['password_env']]
            self.headers['Authorization'] = 'Basic ' + base64.b64encode((options['username'] + ':' + secret).encode()).decode()
        self.max_response = options.get('max_response_bytes', 32 * 1024 * 1024)
        self.timeout = options.get('timeout_seconds', 30)
        if not 1024 <= self.max_response <= 64 * 1024 * 1024 or not 1 <= self.timeout <= 120:
            raise Blocked('Invalid HTTP memory/timeout bound')

    def request(self, method, path, body=None, raw=False):
        if not path.startswith('/') or path.startswith('//'):
            raise Blocked('Relative Elasticsearch API path required')
        connection = (http.client.HTTPSConnection(self.host, self.port, timeout=self.timeout, context=self.context)
                      if self.scheme == 'https' else http.client.HTTPConnection(self.host, self.port, timeout=self.timeout))
        # Connect only to the inspected Docker address; TLS still validates the configured DNS name.
        connection._create_connection = lambda address, timeout, *a, **kw: socket.create_connection((self.address, address[1]), timeout)
        payload = body if raw else (canonical(body).encode() if body is not None else None)
        try:
            connection.request(method, path, body=payload, headers=self.headers)
            response = connection.getresponse()
            data = response.read(self.max_response + 1)
            if len(data) > self.max_response:
                raise Blocked('Response exceeds configured bound; reduce page size or review oversized documents')
            result = decode(data) if data else {}
            if not 200 <= response.status < 300:
                raise HTTPFailure(response.status, result)
            return result
        except (OSError, http.client.HTTPException) as error:
            raise Blocked('Endpoint unavailable: ' + type(error).__name__) from error
        finally:
            connection.close()

    def scroll(self, path, *, page_size=500, query=None, retries=2):
        # A restarted scan replays IDs into a unique disk ledger; never trust an expired cursor.
        for attempt in range(retries + 1):
            cursor = None
            try:
                body = {'size': page_size, '_source': True, 'sort': ['_doc'], 'stored_fields': ['_routing'], 'query': query or {'match_all': {}}}
                page = self.request('POST', path + ('&' if '?' in path else '?') + 'scroll=2m', body)
                total = page.get('hits', {}).get('total')
                if isinstance(total, dict):
                    if total.get('relation') != 'eq':
                        raise Blocked('Approximate scroll total')
                    total = total['value']
                count = 0
                while True:
                    cursor = page.get('_scroll_id', cursor)
                    complete(page)
                    hits = page['hits']['hits']
                    if not hits:
                        if count != total:
                            raise Blocked('Truncated scroll')
                        return
                    if not cursor:
                        raise Blocked('Missing scroll context')
                    count += len(hits)
                    if count > total:
                        raise Blocked('Scroll exceeds exact count')
                    yield hits
                    page = self.request('POST', '/_search/scroll', {'scroll': '2m', 'scroll_id': cursor})
            except HTTPFailure as error:
                if error.status != 404 or attempt == retries:
                    raise
            finally:
                if cursor:
                    try:
                        self.request('DELETE', '/_search/scroll', {'scroll_id': [cursor]})
                    except Blocked:
                        pass  # The original error remains blocking; expired contexts already have no resources.


def complete(response):
    if response.get('timed_out') or response.get('_shards', {}).get('failed', 0):
        raise Blocked('Partial Elasticsearch response')


class Ledger:
    def __init__(self, directory, config):
        self.root = Path(directory).resolve()
        self.root.mkdir(mode=0o700, parents=True, exist_ok=True)
        import fcntl
        self.lock = (self.root / 'lock').open('a')
        try:
            fcntl.flock(self.lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise Blocked('Another migration process holds this journal') from error
        self.config = config
        self.path = self.root / 'state.json'
        self.state = decode(self.path.read_text()) if self.path.exists() else {
            'run_id': uuid.uuid4().hex, 'phase': 'new', 'config_sha256': digest(config)}
        if self.state['config_sha256'] != digest(config):
            raise Blocked('Configuration changed; use a new journal and an explicitly reviewed recovery')
        self.db = sqlite3.connect(self.root / 'documents.sqlite3')
        self.db.execute('PRAGMA synchronous=FULL')
        self.db.execute('PRAGMA journal_mode=DELETE')
        self.db.executescript('''
          CREATE TABLE IF NOT EXISTS documents (
            source_index TEXT, source_type TEXT, id TEXT, target_index TEXT,
            content TEXT, sha256 TEXT, imported INTEGER DEFAULT 0,
            PRIMARY KEY(source_index, source_type, id), UNIQUE(target_index, id));
          CREATE TABLE IF NOT EXISTS observations (
            side TEXT, target_index TEXT, id TEXT, sha256 TEXT,
            PRIMARY KEY(side, target_index, id));
        ''')
        os.chmod(self.root / 'documents.sqlite3', 0o600)
        self.save()

    def save(self, **changes):
        self.state.update(changes)
        atomic(self.path, self.state)

    def event(self, action, **data):
        record = {'at': time.time(), 'action': action, 'phase': self.state['phase'], **data}
        with (self.root / 'events.jsonl').open('a') as stream:
            os.chmod(stream.name, 0o600)
            stream.write(canonical(record) + '\n')
            stream.flush()
            os.fsync(stream.fileno())

    def require(self, *phases):
        if self.state['phase'] not in phases:
            raise Blocked('Phase %s is not one of %s' % (self.state['phase'], ', '.join(phases)))

    def runtime(self, **changes):
        guard = {'run_id': self.state['run_id'], 'phase': self.state['phase'],
                 'queue_prefix': 'es9-' + self.state['run_id'] + '-',
                 'protected_through': self.state.get('protected_through', self.config['protected_through']), **changes}
        atomic(self.root / 'runtime/guard.json', guard)

    def close(self):
        self.db.close()
        self.lock.close()
