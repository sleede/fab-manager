# Instructions for upgrading PostgreSQL

## Automatic upgrade

Fab-manager release 4.2.0 has upgraded its dependency to PostgreSQL from version 9.4 to version 9.6 as the previous won't be maintained from february 2020.
To keep using fab-manager you need to upgrade your installation with the new version.
We've wrote a script to automate the process while keeping your data integrity, but there's some requirements to understand before running it.

- You need to install *curl*, *GNU awk* and *sudo* on your system before running the script. 
  Usually, `apt update && apt install curl gawk sudo`, ran as root, will do the trick but this may change, depending upon your system.
- Your current user must be part of the *docker* and *sudo* groups. 
  Using the root user is a possible alternative, but not recommended.
- A bit of free disk space is also required to perform the data migration. 
  The amount needed depends on your current database size, the script will check it and tell you if there's not enough available space.
- This script should run on any Linux or MacOS systems if you installed PostgreSQL using docker-compose.
  Otherwise, you must perform the upgrade yourself manually.

Once you've understood all the points above, you can run the migration script with the following:

```bash
cd /apps/fabmanager
# do not run as root, elevation will be prompted if needed
\curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/scripts/postgre-upgrade.sh | bash
```

## Manual upgrade

For instructions regarding a manual upgrade, please refer to the official documentation:

- https://www.postgresql.org/docs/9.6/upgrading.html
