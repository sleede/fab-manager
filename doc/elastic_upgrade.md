# Instructions for upgrading ElasticSearch

Fab-manager release 2.6.5 has upgraded its dependency to ElasticSearch from version 1.7 to version 5.6 as the previous was unsupported for months.
To keep using fab-manager you need to upgrade your installation with the new version.
We've wrote a script to automate the process while keeping your data integrity, but there's some requirements to understand before running it.

- You need to install *curl*, *jq* and *sudo* on your system before running the script. 
  Usually, `sudo apt update && sudo apt install curl jq sudo` will do the trick but this may change, depending upon your system.
- You'll need at least 4GB of RAM for the data migration to complete successfully.
  The script will try to add 4GB of swap memory if this requirement is detected as missing but this will consume you hard disk space (see below).
- 1,17GB of free disk space are also required to perform the data migration.
  Please ensure that you'll have enough space, considering the point above. The script won't run otherwise.
- This script will run on any Debian compatible OS (like Ubuntu) and on MacOS X, on any other systems you'll need to perform the upgrade yourself manually.
- If your ElasticSearch instance uses replicas shards, you can't use this script and you must perform a manual upgrade.

Once you've understood all the points above, you can run the migration script with the following:

```bash
cd /apps/fabmanager
# do not run as root, elevation will be prompted if needed
\curl https://raw.githubusercontent.com/LaCasemate/fab-manager/master/scripts/elastic-upgrade.sh | bash
```
