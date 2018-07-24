# Instructions for upgrading ElasticSearch

Fab-manager release 2.6.5 has upgraded its dependency to ElasticSearch from version 1.7 to version 5.6 as the previous was unsupported for months.
To keep using fab-manager you need to upgrade your installation with the new version.
We've wrote a script to automate the process while keeping your data integrity, but there's some requirements to understand before running it.

- You need to install *curl*, *jq* and *sudo* on your system before running the script. 
  Usually, `apt update && apt install curl jq sudo`, ran as root, will do the trick but this may change, depending upon your system.
- You'll need at least 4GB of RAM for the data migration to complete successfully.
  The script will try to add 4GB of swap memory if this requirement is detected as missing but this will consume you hard disk space (see below).
- 1,17GB of free disk space are also required to perform the data migration.
  Please ensure that you'll have enough space, considering the point above. The script won't run otherwise.
- This script will run on any Linux or Macintoch systems if you installed ElasticSearch using docker or docker-compose.
  Otherwise, only Debian compatible OS (like Ubuntu) and MacOS X are supported for classical installations. On any other cases you'll need to perform the upgrade yourself manually.
- If your ElasticSearch instance uses replicas shards, you can't use this script and you must perform a manual upgrade (if you have a standard fab-manager installation and you don't understand what this mean, you're probably not concerned).

Once you've understood all the points above, you can run the migration script with the following:

```bash
cd /apps/fabmanager
# do not run as root, elevation will be prompted if needed
\curl https://raw.githubusercontent.com/LaCasemate/fab-manager/master/scripts/elastic-upgrade.sh | bash
```

For instructions regarding a manual upgrade, please refer to the official documentation:
- https://www.elastic.co/guide/en/elasticsearch/reference/2.4/restart-upgrade.html
- https://www.elastic.co/guide/en/elasticsearch/reference/5.6/restart-upgrade.html