# Install Fabmanager app in production with Docker

This README tries to describe all steps to put a fabmanager app into production on a server, based on a solution using Docker and DigitalOcean.
In order to make it work, please use the same directories structure as described in this guide in your fabmanager app folder.

## Preliminary steps

### file docker/env

Make a copy of the **env.example** and use it as a starting point.
Set all the environment variables needed by your application. Please refer to the [FabManager README](https://github.com/LaCasemate/fab-manager/blob/master/README.md) for explanations about those variables.

### file docker/nginx_with_ssl.conf.example

* Replace **MAIN_DOMAIN** (example: fab-manager.com).
* Replace **URL_WITH_PROTOCOL_HTTPS** (example: https://www.fab-manager.com).
* Replace **ANOTHER_URL_1**, **ANOTHER_URL_2** (example: .fab-manager.fr)

Side note:
* Use nginx.conf.example if you are not using **SSL**

### setup the server

Go to **DigitalOcean** and create a Droplet with operating system coreOS **stable**.
You need at least 2GB of addressable memory (RAM + swap) to install and use FabManager.
Choose a datacenter. Set the hostname as your domain name.

### Buy a domain name and link it with the droplet

1. Buy a domain name on OVH
2. Replace the IP address of the domain with the droplet's IP (you can enable the flexible ip and use it)
3. **Do not** try to access your domain name right away, DNS are not aware of the change yet so **WAIT** and be patient. 

### Connect to the droplet via SSH

You can already connect to the server with this command: `ssh core@droplet-ip`. When DNS propagation will be done, you will be able to
connect to the server with `ssh core@your-domain-name`.

### Create SWAP file in coreOS

Firstly, switch to sudo and create a swap file

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

Copy the previously customized `env.example` file as `/home/core/fabmanager/config/env`

```bash
mkdir -p /home/core/fabmanager/config/nginx
```

Copy the previously customized `nginx_with_ssl.conf.example` as `/home/core/fabmanager/config/nginx/fabmanager.conf`
OR
Copy the previously customized `nginx.conf.example` as `/home/core/fabmanager/config/nginx/fabmanager.conf` if you do not want ssl support (not recommended !).

### SSL certificate with LetsEncrypt

Let's Encrypt is a new Certificate Authority that is free, automated, and open.
Let’s Encrypt certificates expire after 90 days, so automation of renewing your certificates is important.
Here is the setup for a systemd timer and service to renew the certificates and reboot the app Docker container:

```bash
mkdir -p /home/core/fabmanager/config/nginx/ssl
```
Run `openssl dhparam -out dhparam.pem 4096` in the folder /home/core/fabmanager/config/nginx/ssl (generate dhparam.pem file)
```bash
mkdir -p /home/core/fabmanager/letsencrypt/config/
```
Copy the previously customized `webroot.ini.example` as `/home/core/fabmanager/letsencrypt/config/webroot.ini`
```bash
mkdir -p /home/core/fabmanager/letsencrypt/etc/webrootauth
```

Run `docker pull quay.io/letsencrypt/letsencrypt:latest`

Create file (with sudo) /etc/systemd/system/letsencrypt.service and paste the following configuration into it:

```bash
[Unit]
Description=letsencrypt cert update oneshot
Requires=docker.service

[Service]
Type=oneshot  
ExecStart=/usr/bin/docker run --rm --name letsencrypt -v "/home/core/fabmanager/log:/var/log/letsencrypt" -v "/home/core/fabmanager/letsencrypt/etc:/etc/letsencrypt" -v "/home/core/fabmanager/letsencrypt/config:/letsencrypt-config" quay.io/letsencrypt/letsencrypt:latest -c "/letsencrypt-config/webroot.ini" certonly
ExecStartPost=-/usr/bin/docker restart fabmanager_nginx_1  
```

Create file (with sudo) /etc/systemd/system/letsencrypt.timer and paste the following configuration into it:
```bash
[Unit]
Description=letsencrypt oneshot timer  
Requires=docker.service

[Timer]
OnCalendar=*-*-1 06:00:00
Persistent=true
Unit=letsencrypt.service

[Install]
WantedBy=timers.target
```

That's all for the moment. Keep on with the installation, we'll complete that part after deployment in the [Generate SSL certificate by Letsencrypt](#generate-ssl-cert-letsencrypt).

### Install docker-compose

```bash
curl -L https://github.com/docker/compose/releases/download/1.7.1/docker-compose-`uname -s`-`uname -m` > ./docker-compose
sudo mkdir -p /opt/bin
sudo mv docker-compose /opt/bin/
sudo chmod +x /opt/bin/docker-compose
```

Then copy docker-compose.yml to your app folder `/home/core/fabmanager`.

## Deployment

### pull images

```bash
docker-compose pull
```

### setup database 

```bash
docker-compose run --rm fabmanager bundle exec rake db:create # create the database
docker-compose run --rm fabmanager bundle exec rake db:migrate # run all the migrations
docker-compose run --rm fabmanager bundle exec rake db:seed # seed the database
```

### build assets

`docker-compose run --rm fabmanager bundle exec rake assets:precompile`

### prepare elastic (search engine)

`docker-compose run --rm fabmanager bundle exec rake fablab:es_build_stats`

#### start all services

`docker-compose up -d`


### Generate SSL certificate by Letsencrypt 
<a name="generate-ssl-cert-letsencrypt"></a>

**Important: app must be run before starting letsencrypt**

Start letsencrypt service :
```bash
sudo systemctl start letsencrypt.service
```

If the certificate was successfully generated then update the nginx configuration file and activate the ssl port and certificate
editing the file `/home/core/fabmanager/config/nginx/fabmanager.conf`.

Remove your app container and run your app to apply the changes running the following commands:
```bash
docker-compose down
docker-compose up -d
```

Finally, if everything is ok, start letsencrypt timer to update the certificate every 1st of the month :

```bash
sudo systemctl enable letsencrypt.timer
sudo systemctl start letsencrypt.timer
(check) sudo systemctl list-timers
```

## Docker utils

### Restart app

`docker restart fabmanager-app`

### Remove app

`docker rm -f fabmanager-app`

### Open a bash in the app context

`docker exec -it fabmanager-app bash`

### Show services status

`docker-compose ps`

### Restart all services

`docker-compose restart`

## How to update Fabmanager (to the last version)

When a new version is available, this is how to update fabmanager app in a production environment, using docker-compose :

### go to your app folder

`cd fabmananger`

### pull last docker images 

`docker-compose pull`

### stop the app

`docker-compose stop fabmanager`

### remove old assets

`sudo rm -Rf public/assets/`

### compile new assets

`docker-compose run --rm fabmanager bundle exec rake assets:precompile`

### run specific commands

Do not forget to check if there are any command to run for your upgrade. Those commands 
are always specified in the [CHANGELOG](https://github.com/LaCasemate/fab-manager/blob/master/CHANGELOG.md) and prefixed by *[TODO DEPLOY]*. 
They are also present in the [release pages](https://github.com/LaCasemate/fab-manager/releases).

They execute specific tasks so they can't be automatic and have to be run by hand.

### restart all containers

```bash
  docker-compose down
  docker-compose up -d
```

You can check that all containers are running with `docker ps`.

### Good to know

#### Is it possible to update several versions at the same time ?

Yes, indeed. It's the default behaviour as `docker-compose pull` command will fetch the latest versions of the docker images. 
Be sure to run all the specific commands listed in the [CHANGELOG](https://github.com/LaCasemate/fab-manager/blob/master/CHANGELOG.md) between your actual
and the new version in sequential order. (Example: to update from 2.4.0 to 2.4.3, you will run the specific commands for the 2.4.1, then for the 2.4.2 and then for the 2.4.3).