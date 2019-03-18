# Instructions for upgrading ElasticSearch

## Automatic upgrade

Fab-manager release 2.6.5 has upgraded its dependency to ElasticSearch from version 1.7 to version 5.6 as the previous was unsupported for months.
To keep using fab-manager you need to upgrade your installation with the new version.
We've wrote a script to automate the process while keeping your data integrity, but there's some requirements to understand before running it.

- You need to install *curl*, *jq*, *GNU awk* and *sudo* on your system before running the script. 
  Usually, `apt update && apt install curl jq sudo gawk`, ran as root, will do the trick but this may change, depending upon your system.
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

## Manual upgrade

For instructions regarding a manual upgrade, please refer to the official documentation:

- https://www.elastic.co/guide/en/elasticsearch/reference/2.4/restart-upgrade.html
- https://www.elastic.co/guide/en/elasticsearch/reference/5.6/restart-upgrade.html

## Restart the upgrade

So something goes wrong and the upgrade failed during ES 2.4 reindexing? 
Sad news, but everything isn't lost, follow this procedure to start the upgrade again.

First, check the status of your indices:

```bash
# Replace fabmanager_elasticsearch_1 in the next command with your container's name. 
# You can get it running `docker ps`
ES_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' fabmanager_elasticsearch_1)
curl "$ES_IP:9200/_cat/indices?v"
```

You should get something like this:
```
health status index     pri rep docs.count docs.deleted store.size pri.store.size 
green  open   fablab_24   1   0       1944            0        1mb            1mb 
green  open   stats_24    1   0          0            0      2.8mb           104b 
green  open   stats       5   0      13515            0      2.7mb          2.7mb 
green  open   fablab      5   0       1944            4      1.2mb          1.2mb 
```

Here, we can see that the migration is not complete, as *docs.count* are not equal for `stat_24` and `stats`.

Let's remove the bogus indices:

```bash
curl -XDELETE "$ES_IP:9200/fablab_24"
curl -XDELETE "$ES_IP:9200/stats_24"
```

Then, edit your [docker-compose.yml](../docker/docker-compose.yml) and change the *elasticsearch* block according to the following: 

<table>
<tr><td>
<pre style="max-width:350px; overflow-y: scroll">
  elasticsearch:
    image: elasticsearch:2.4
    ulimits:
      memlock:
        soft: -1
        hard: -1
    environment:
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - ${PWD}/elasticsearch/config:/usr/share/elasticsearch/config
      - ${PWD}/elasticsearch:/usr/share/elasticsearch/data
    restart: always
</pre>
</td>
<td>
=>
</td>
<td>
<pre style="max-width:350px; overflow-y: scroll">
  elasticsearch:
    image: elasticsearch:1.7
    volumes:
      - ${PWD}/elasticsearch:/usr/share/elasticsearch/data
    restart: always
</pre>
</td></tr>
</table>

Now you can safely restart the upgrade script.

```bash
\curl https://raw.githubusercontent.com/LaCasemate/fab-manager/master/scripts/elastic-upgrade.sh | bash
```

## Debugging the upgrade

You can check for any error during container startup, using:

```bash
docker-compose logs elasticsearch 
```

## Skip the upgrade

The upgrade is not working and you can't debug it?
You can skip it by deleting your ES database, installing ES 5.6 and resynchronizing ES from your PostgreSQL database.

**This is not recommended on old installations as this can lead to data losses.**

Here's the procedure:

```bash
curl -XDELETE "$ES_IP:9200/fablab"
curl -XDELETE "$ES_IP:9200/stats"
# delete any other index, if applicable
```
Stop and remove your container, then edit your [docker-compose.yml](../docker/docker-compose.yml) and set the following:

```yml
  elasticsearch:
    image: elasticsearch:5.6
    ulimits:
      memlock:
        soft: -1
        hard: -1
    environment:
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - ${PWD}/elasticsearch/config:/usr/share/elasticsearch/config
      - ${PWD}/elasticsearch:/usr/share/elasticsearch/data
    restart: always
```

Copy [elasticsearch.yml](../docker/elasticsearch.yml) and [log4j2.properties](../docker/log4j2.properties) to `elasticsearch/config`, then pull and restart your containers.

Finally reindex your data:
```bash
rake fablab:es:build_stats
rake fablab:es:generate_stats[3000]
rake fablab:es:build_projects_index
```
