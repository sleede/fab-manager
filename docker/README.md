
## Docker

Docker is an application deployment software.

## PREPARE HOST COREOS
Install VPS WITH Version coreOS STABLE (Ex : on DigitalOcean)

### Creating Swap File in CoreOS

Firstly, switch to sudo and create swap file
```bash
sudo -i  
touch /2GiB.swap  
chattr +C /2GiB.swap  
fallocate -l 2048m /2GiB.swap  
chmod 600 /2GiB.swap  
mkswap /2GiB.swap  
```

Create file /etc/systemd/system/swap.service with
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

## PREPARE FOLDERS AND ENV CONFIG ON HOST

mkdir -p /home/core/fabmanager/config
MOVE docker/env.example to /home/core/fabmanager/config/env  
CUSTOM ENV
mkdir -p /home/core/fabmanager/config/nginx
MOVE docker/nginx.conf.example to /home/core/fabmanager/config/nginx/fabmanager.conf  
CUSTOM fabmanager.conf

IF SSL 
mkdir -p /home/core/fabmanager/config/nginx/ssl
Move your crt and deprotected key
MOVE docker/nginx_with_ssl.conf.example to /home/core/fabmanager/config/nginx/fabmanager.conf  
CUSTOM fabmanager.conf


## DEPLOY DOCKERS CONTAINERS ON HOST

   
```bash
docker pull redis:3.0
docker pull postgres:9.4
docker pull elasticsearch:1.7
docker pull sleede/fabmanager

docker run --restart=always -d --name=fabmanager-postgres -v /home/core/fabmanager/postgresql:/var/lib/postgresql/data postgres:9.4
docker run --restart=always -d --name=fabmanager-redis -v /home/core/fabmanager/redis:/data redis:3.0
docker run --restart=always  -d --name=fabmanager-elastic -v /home/core/fabmanager/elasticsearch:/usr/share/elasticsearch/data elasticsearch:1.7
```

### DB CREATE

```bash
docker run --rm \
           --link=fabmanager-postgres:postgres \
           --link=fabmanager-redis:redis \
           --link=fabmanager-elastic:elasticsearch \
           -e RAILS_ENV=production \
           --env-file /home/core/fabmanager/config/env \
           sleede/fabmanager \
           bundle exec rake db:create
```

### DB MIGRATE

```bash
docker run --rm \
           --link=fabmanager-postgres:postgres \
           --link=fabmanager-redis:redis \
           --link=fabmanager-elastic:elasticsearch \
           -e RAILS_ENV=production \
           --env-file /home/core/fabmanager/config/env \
           sleede/fabmanager \
           bundle exec rake db:migrate
```

### DB SEED

```bash
docker run --rm \
           --link=fabmanager-postgres:postgres \
           --link=fabmanager-redis:redis \
           --link=fabmanager-elastic:elasticsearch \
           -e RAILS_ENV=production \
           --env-file /home/core/fabmanager/config/env \
           sleede/fabmanager \
           bundle exec rake db:seed
```


### PREPARE ELASTIC

```bash
docker run --rm \
             --link=fabmanager-postgres:postgres \
             --link=fabmanager-postgres:postgres \
             --link=fabmanager-redis:redis \
             --link=fabmanager-elastic:elasticsearch \
             -e RAILS_ENV=production \
             --env-file /home/core/fabmanager/config/env \
             sleede/fabmanager \
             bundle exec rake fablab:es_build_stats
```


### recreate every versions of images

```bash
docker run --rm \
             --link=fabmanager-postgres:postgres \
             --link=fabmanager-redis:redis \
             --link=fabmanager-elastic:elasticsearch \
             -e RAILS_ENV=production \
             --env-file /home/core/fabmanager/config/env \
             -v /home/core/fabmanager/public/uploads:/usr/src/app/public/uploads \
             sleede/fabmanager \
             bundle exec rake fablab:build_images_versions
```


### BUILD ASSETS

```bash
docker run --rm \
             --link=fabmanager-postgres:postgres \
             --link=fabmanager-redis:redis \
             --link=fabmanager-elastic:elasticsearch \
             -e RAILS_ENV=production \
             --env-file /home/core/fabmanager/config/env \
             -v /home/core/fabmanager/public/assets:/usr/src/app/public/assets \
             sleede/fabmanager \
             bundle exec rake assets:precompile

docker run --rm -v /home/core/fabmanager/public/assets:/usr/src/app/public/assets sleede/fabmanager cp vendor/assets/components/select2/select2.png public/assets/select2.png
docker run --rm -v /home/core/fabmanager/public/assets:/usr/src/app/public/assets sleede/fabmanager cp vendor/assets/components/select2/select2x2.png public/assets/select2x2.png
docker run --rm -v /home/core/fabmanager/public/assets:/usr/src/app/public/assets sleede/fabmanager cp vendor/assets/components/select2/select2-spinner.gif public/assets/select2-spinner.gif
```


### RUN APP

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
             sleede/fabmanager
```


### for debug

```bash
docker run --rm -it \
             --link=fabmanager-postgres:postgres \
             --link=fabmanager-redis:redis \
             --link=fabmanager-elastic:elasticsearch \
             -e RAILS_ENV=production \
             --env-file /home/core/fabmanager/config/env \
             sleede/fabmanager \
             bash
```
