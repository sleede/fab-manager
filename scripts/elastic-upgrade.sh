#!/usr/bin/env bash
set -euo pipefail
echo 'In-place Elasticsearch upgrades are unsupported by this release.' >&2
echo 'Preserve the ES5 image, volume and credentials. Use scripts/elasticsearch_migration/README.md and the ES03 journaled transfer into a new ES9 volume.' >&2
exit 3
