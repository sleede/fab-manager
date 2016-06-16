# full procedure to put into production a fabmanager app with Docker

This README tries to describe all steps to put a fabmanager app into production on a server, based on a solution using Docker and DigitalOcean.
In order to make all this stuff working, please use the same directories structure as described in this guide in your fabmanager app folder.

### docker/env

Make a copy of the **env.example** and use it as a starting point.
List all the environment variables needed by your application.

### docker/nginx_with_ssl.conf.example

* Use nginx.conf.example especially if you are not using **SSL**
* Replace **MAIN_DOMAIN** (example: fab-manager.com).
* Replace **URL_WITH_PROTOCOL_HTTPS** (example: https://www.fab-manager.com).
* Replace **ANOTHER_URL_1**, **ANOTHER_URL_2** (example: .fab-manager.fr)



## Things are getting serious, starting deployment process guys


### setup the server

Go to **DigitalOcean** and create a Droplet with operating system coreOS **stable**.
You need at least 2GB of addressable memory (RAM + swap) to install and use FabManager!.
Choose datacenter. Set hostname as your domain name.


### Buy domain name and link it with the droplet

1. Buy a domain name on OVH
2. Replace IP of the domain with droplet's IP (you can enable the flexible ip and use it)
3. **Do not** fuck up trying to access your domain name right away, DNS are not aware of the change yet so **WAIT** and be patient.


### Connect to the droplet via SSH

You can already connect to the server with this command: `ssh core@droplet-ip`. When DNS propagation will be done, you will be able to
connect to the server with `ssh core@your-domain-name`.



### Create SWAP file in coreOS

Firstly, switch to sudo and create swap file

```bash
sudo -i  
touch /2GiB.swap  
chattr +C /2GiB.swap  
fallocate -l 2048m /2GiB.swap  
chmod 600 /2GiB.swap  
mkswap /2GiB.swap  
```

Create file **/etc/systemd/system/swap.service**, filling it with the lines:

```bash
[Unit]  
Description=Turn on swap  
[Service]  
Type=oneshot  
Environment="SWAPFILE=/2GiB.swap"  
RemainAfterExit=true  
ExecStartPre=/usr/sbin/losetup -f ${SWAPFILE}  
ExecStart=/usr/bin/sh -c "/sbin/swapon $(/usr/sbin/losetup -j ${SWAPFILE} | /usr/bin/cut -d : -f 1)"  
ExecStop=/usr/bin/sh -c "/sbin/swapoff $(/usr/sbin/losetup -j ${SWAPFILE} | /usr/bin/cut -d : -f 1)"  
ExecStopPost=/usr/bin/sh -c "/usr/sbin/losetup -d $(/usr/sbin/losetup -j ${SWAPFILE} | /usr/bin/cut -d : -f 1)"  
[Install]  
WantedBy=multi-user.target  
```

Then add service and start:

```bash
systemctl enable /etc/systemd/system/swap.service  
systemctl start swap
exit
```

### Setup folders and env file

```bash
mkdir -p /home/core/fabmanager/config
```

Copy the previously customized `env` file as `/home/core/fabmanager/config/env`.

```bash
mkdir -p /home/core/fabmanager/config/nginx
```

Copy the previously customized `nginx.conf` as `/home/core/fabmanager/config/nginx/fabmanager.conf`.


### Deploy dockers containers on host

```bash
docker pull redis:3.0
docker pull postgres:9.4
docker pull elasticsearch:1.7
docker pull sleede/fab-manager

docker run --restart=always -d --name=fabmanager-postgres -v /home/core/fabmanager/postgresql:/var/lib/postgresql/data postgres:9.4
docker run --restart=always -d --name=fabmanager-redis -v /home/core/fabmanager/redis:/data redis:3.0
docker run --restart=always  -d --name=fabmanager-elastic -v /home/core/fabmanager/elasticsearch:/usr/share/elasticsearch/data elasticsearch:1.7
```

### Rails specific commands

#### DB CREATE

```bash
docker run --rm \
           --link=fabmanager-postgres:postgres \
           --link=fabmanager-redis:redis \
           --link=fabmanager-elastic:elasticsearch \
           -e RAILS_ENV=production \
           --env-file /home/core/fabmanager/config/env \
           sleede/fab-manager \
           bundle exec rake db:create
```

#### DB MIGRATE

```bash
docker run --rm \
           --link=fabmanager-postgres:postgres \
           --link=fabmanager-redis:redis \
           --link=fabmanager-elastic:elasticsearch \
           -e RAILS_ENV=production \
           --env-file /home/core/fabmanager/config/env \
           sleede/fab-manager \
           bundle exec rake db:migrate
```

#### DB SEED

```bash
docker run --rm \
           --link=fabmanager-postgres:postgres \
           --link=fabmanager-redis:redis \
           --link=fabmanager-elastic:elasticsearch \
           -e RAILS_ENV=production \
           --env-file /home/core/fabmanager/config/env \
           sleede/fab-manager \
           bundle exec rake db:seed
```


#### PREPARE ELASTIC

```bash
docker run --rm \
             --link=fabmanager-postgres:postgres \
             --link=fabmanager-postgres:postgres \
             --link=fabmanager-redis:redis \
             --link=fabmanager-elastic:elasticsearch \
             -e RAILS_ENV=production \
             --env-file /home/core/fabmanager/config/env \
             sleede/fab-manager \
             bundle exec rake fablab:es_build_stats
```


#### BUILD ASSETS

```bash
docker run --rm \
             --link=fabmanager-postgres:postgres \
             --link=fabmanager-redis:redis \
             --link=fabmanager-elastic:elasticsearch \
             -e RAILS_ENV=production \
             --env-file /home/core/fabmanager/config/env \
             -v /home/core/fabmanager/public/assets:/usr/src/app/public/assets \
             sleede/fab-manager \
             bundle exec rake assets:precompile
```


#### RUN APP

```bash
docker run --restart=always -d --name=fabmanager \
             -p 80:80 \
             -p 443:443 \
             --link=fabmanager-postgres:postgres \
             --link=fabmanager-redis:redis \
             --link=fabmanager-elastic:elasticsearch \
             -e RAILS_ENV=production \
             -e RACK_ENV=production \
             --env-file /home/core/fabmanager/config/env \
             -v /home/core/fabmanager/config/nginx:/etc/nginx/conf.d \
             -v /home/core/fabmanager/public/assets:/usr/src/app/public/assets \
             -v /home/core/fabmanager/public/uploads:/usr/src/app/public/uploads \
             -v /home/core/fabmanager/invoices:/usr/src/app/invoices \
             -v /home/core/fabmanager/log:/var/log/supervisor \
             sleede/fab-manager
```



### Dockers utils

#### Restart app

`docker restart fabmanager-app`

#### Remove app

`docker rm -f fabmanager-app`

#### Open a bash in the app context

`docker exec -it fabmanager-app bash`




### Docker Compose

#### download docker compose https://github.com/docker/compose/releases

```bash
curl -L https://github.com/docker/compose/releases/download/1.7.1/docker-compose-`uname -s`-`uname -m` > ./docker-compose
sudo mkdir -p /opt/bin
sudo mv docker-compose /opt/bin/
sudo chmod +x /opt/bin/docker-compose
```

#### Setup folders and env file

```bash
mkdir -p /home/core/fabmanager/config
```

Copy the previously customized `env` file as `/home/core/fabmanager/config/env`.

```bash
mkdir -p /home/core/fabmanager/config/nginx
```

Copy the previously customized `nginx.conf` as `/home/core/fabmanager/config/nginx/fabmanager.conf`.

#### copy docker-compose.yml to /home/core/

#### pull images

`docker-compose pull`

#### create/migrate/seed db

`docker-compose run --rm fabmanager bundle exec rake db:setup`

#### build assets

`docker-compose run --rm fabmanager bundle exec rake assets:precompile`

#### PREPARE ELASTIC
`docker-compose run --rm fabmanager bundle exec rake fablab:es_build_stats`

#### run create and run all services

`docker-compose up -d`

#### restart all services

`docker-compose restart`

#### show services status

`docker-compose ps`

#### update service fabmanager, rebuild assets and restart fabmanager

```bash
docker-compose pull fabmanager
docker-compose stop fabmanager
sudo rm -rf fabmanager/public/assets
docker-compose run --rm fabmanager bundle exec rake assets:precompile
docker-compose start fabmanager
```
