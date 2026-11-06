# Elasticsearch 9 single-node deployment

Use this Compose file for a **new** local target. The reviewed official image is
`docker.elastic.co/elasticsearch/elasticsearch:9.5.6`. Never point it at an ES5
volume or restore an ES5 snapshot into it. The [operator runbook](../../doc/elasticsearch_deployment.md)
covers setup, external services, upgrade, backups, maintenance and rollback.

On a Linux Docker host with Python 3, OpenSSL and sufficient disk/RAM:

```sh
export ES9_SECRETS_DIR=/srv/fm-private/es9
python3 scripts/elasticsearch_deployment.py prepare --secrets "$ES9_SECRETS_DIR"
docker compose -p fm-es9-new -f docker/elasticsearch9/docker-compose.yml config --quiet
docker compose -p fm-es9-new -f docker/elasticsearch9/docker-compose.yml up -d elasticsearch
# Obtain the private address without publishing a host port; TLS still checks DNS elasticsearch.
ES9_ID=$(docker compose -p fm-es9-new -f docker/elasticsearch9/docker-compose.yml ps -q elasticsearch)
ES9_IP=$(docker inspect "$ES9_ID" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
python3 scripts/elasticsearch_deployment.py provision --secrets "$ES9_SECRETS_DIR" --address "$ES9_IP"
```

Retry provisioning while the new server starts. Its health check uses the limited
`fm_health` account, so it becomes healthy **after** provisioning. Provisioning is
an explicit bootstrap operation for an empty local cluster. It refuses business
indices and is not a recreation or external-service procedure. Never rerun
`prepare` on a populated secrets directory: the tool refuses to replace its CA or
passwords. Keep this directory, including the CA private key, outside Git and back
it up securely. The CA key is not mounted into Elasticsearch or Rails.

The official process uses uid 1000/gid 0. Root preparation sets the server key and
bootstrap password ownership accordingly; an unprivileged operator must arrange
equivalent permissions before startup. Give only the selected application uid
read access to its password file. Do not make private keys world-readable.

Rails and Sidekiq join the private `fm-es9-new_search` network. Mount only the public
CA and the `runtime_password` file, configure `ELASTICSEARCH_USERNAME=fm_runtime`,
`ELASTICSEARCH_PASSWORD_FILE=/run/es-secrets/runtime_password`,
`ELASTICSEARCH_URL=https://elasticsearch:9200` and
`ELASTICSEARCH_CA_FILE=/run/es-certificates/ca.crt`. Initialize a **new** installation
with `fablab:es:initialize` under the separate `fm_migration` identity, then run
`fablab:es:validate` under runtime credentials. Existing histories require the
[ES03 transfer](../../scripts/elasticsearch_migration/README.md), never a statistics rebuild.

Defaults: 512 MiB heap, 2 GiB container limit, 2 CPUs, single-node discovery,
verified HTTP TLS, active Basic license, native filesystem snapshot repository,
new named data/repository volumes, internal network and **no published 9200/9300**.
`ES9_HEAP`, `ES9_MEMORY` and `ES9_CPUS` are explicit sizing overrides, not production
capacity guarantees. The permissions-only init container has no network and only
the snapshot volume. Historical Groovy/Log4j configuration is not loaded.

After recreating Elasticsearch with the same image, volumes and secret directory,
check its health, cluster UUID and application access; do not provision it again.
Stop with the same project/file and `stop`. Retain the data, repositories, private
CA and credentials. This supported mode is a single node; it does not configure
multi-node discovery, transport TLS, high availability or automatic certificate renewal.

The official distribution uses [ELv2](https://www.elastic.co/licensing/elastic-license).
Only [Basic features](https://www.elastic.co/subscriptions) are used here; no trial
or paid feature is enabled. Review the distribution conditions for the intended use.
