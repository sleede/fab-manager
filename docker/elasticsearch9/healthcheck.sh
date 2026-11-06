#!/usr/bin/env bash
set -euo pipefail
curl --fail --silent --show-error --max-time 8 \
  --cacert /usr/share/elasticsearch/config/certs/ca.crt \
  --config /run/secrets/es_health_curl \
  'https://elasticsearch:9200/_cluster/health?wait_for_status=yellow&timeout=5s' \
  | grep -q '"timed_out":false'
