# Install Fabmanager app in production with Docker

This README tries to describe all the steps to put a fabmanager app into production on a server, based on a solution using Docker and DigitalOcean.
In order to make it work, please use the same directories structure as described in this guide in your fabmanager app folder.

##### Table of contents

1. [Preliminary steps](#preliminary-steps)<br/>
1.1. [docker/env file](#docker-env)<br/>
1.2. [docker/nginx_with_ssl.conf.example file](#nginx-conf)<br/>
1.3. [setup the server](#setup-server)<br/>
1.4. [buy a domain name and link it with the droplet](#buy-domain-link-droplet)<br/>
1.5. [connect to the droplet via SSH](#connect-to-droplet)<br/>
1.6. [create SWAP file in coreOs](#create-swap-file)<br/>
1.7. [setup folders and env file](#setup-folders-env-file)<br/>
1.8. [SSL certificate with LetsEncrypt](#ssl-certificate-letsencrypt)<br/>
1.9. [install docker-compose](#install-docker-compose)
2. [Deployment](#deployment)<br/>
2.1. [pull images](#pull-images)<br/>
2.2. [setup database](#setup-database)<br/>
2.3. [build assets](#build-assets)<br/>
2.4. [prepare Elasticsearch (search engine)](#prepare-elastic)<br/>
2.5. [start all services](#start-services)
3. [Generate SSL certificate by Letsencrypt](#generate-sll-cert-letsencrypt)
4. [Docker utils](#docker-utils)
5. [Fabmanager update](#update-fabmanager)<br/>
5.1. [Steps](#update-steps)<br/>
5.2. [Good to know](#good-to-know)

<a id="preliminary-steps"></a>
## Preliminary steps

<a id="docker-env"></a>
### docker/env file

Make a copy of the **docker/env.example** file and use it as a starting point.
Set all the environment variables needed by your application. Please refer to the [FabManager README](https://github.com/LaCasemate/fab-manager/blob/master/README.md) for explanations about those variables.

<a id="nginx-conf"></a>
### docker/nginx_with_ssl.conf.example file

* Replace **MAIN_DOMAIN** (example: fab-manager.com).
* Replace **URL_WITH_PROTOCOL_HTTPS** (example: https://www.fab-manager.com).
* Replace **ANOTHER_URL_1**, **ANOTHER_URL_2** (example: .fab-manager.fr)

**Use nginx.conf.example if you don't want SSL for your app.**

<a id="setup-server"></a>
### setup the server

Go to [DigitalOcean](https://www.digitalocean.com/) and create a Droplet with operating system coreOS **stable**.
You need at least 2GB of addressable memory (RAM + swap) to install and use FabManager.
Choose a datacenter. Set the hostname as your domain name.

<a id="buy-domain-link-droplet"></a>
### buy a domain name and link it with the droplet

1. Buy a domain name on [OVH](https://www.ovh.com/fr/)
2. Replace the IP address of the domain with the droplet's IP (you can enable the flexible ip and use it)
3. **Do not** try to access your domain name right away, DNS are not aware of the change yet so **WAIT** and be patient. 

<a id="connect-to-droplet"></a>
### connect to the droplet via SSH

You can already connect to the server with this command: `ssh core@droplet-ip`. When DNS propagation will be done, you will be able to
connect to the server with `ssh core@your-domain-name`.

<a id="create-swap-file"></a>
### create SWAP file in coreOS

Switch to sudo and create a swap file:

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

Then enable the service and start it:

```bash
systemctl enable /etc/systemd/system/swap.service  
systemctl start swap
exit
```

<a id="setup-folders-env-file"></a>
### setup folders and env file

Create the config folder:
```bash
mkdir -p /home/core/fabmanager/config
```

Then, copy the previously customized `env.example` file as `/home/core/fabmanager/config/env`

Create the nginx folder:
```bash
mkdir -p /home/core/fabmanager/config/nginx
```

Then,
Copy the previously customized `nginx_with_ssl.conf.example` as `/home/core/fabmanager/config/nginx/fabmanager.conf`

**OR**

Copy the previously customized `nginx.conf.example` as `/home/core/fabmanager/config/nginx/fabmanager.conf` if you do not want to use ssl (not recommended !).

<a id="ssl-certificate-letsencrypt"></a>
### SSL certificate with LetsEncrypt

**FOLLOW THOSE INSTRUCTIONS ONLY IF YOU WANT TO USE SSL**.

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

<a id="install-docker-compose"></a>
### Install docker-compose

```bash
curl -L https://github.com/docker/compose/releases/download/1.7.1/docker-compose-`uname -s`-`uname -m` > ./docker-compose
sudo mkdir -p /opt/bin
sudo mv docker-compose /opt/bin/
sudo chmod +x /opt/bin/docker-compose
```

Then copy docker-compose.yml to your app folder `/home/core/fabmanager`.

<a id="deployment"></a>
## Deployment

<a id="pull-images"></a>
### pull images

```bash
docker-compose pull
```

<a id="setup-database"></a> 
### setup database

```bash
docker-compose run --rm fabmanager bundle exec rake db:create # create the database
docker-compose run --rm fabmanager bundle exec rake db:migrate # run all the migrations
docker-compose run --rm fabmanager bundle exec rake db:seed # seed the database
```

<a id="build-assets"></a>
### build assets

`docker-compose run --rm fabmanager bundle exec rake assets:precompile`

<a id="prepare-elastic"></a>
### prepare Elasticsearch (search engine)

`docker-compose run --rm fabmanager bundle exec rake fablab:es_build_stats`

<a id="start-services"></a>
#### start all services

`docker-compose up -d`

<a id="generate-ssl-cert-letsencrypt"></a>
### Generate SSL certificate by Letsencrypt 

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

<a id="docker-utils"></a>
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

<a id="update-fabmanager"></a>
## Fabmanager update

*This procedure updates fabmanager to the last version by default.*

<a id="update-steps"></a>
### Steps


When a new version is available, this is how to update fabmanager app in a production environment, using docker-compose :

1. go to your app folder

`cd fabmananger`

2. pull last docker images 

`docker-compose pull`

3. stop the app

`docker-compose stop fabmanager`

4. remove old assets

`sudo rm -Rf public/assets/`

5. compile new assets

`docker-compose run --rm fabmanager bundle exec rake assets:precompile`

6. run specific commands

Do not forget to check if there are commands to run for your upgrade. Those commands 
are always specified in the [CHANGELOG](https://github.com/LaCasemate/fab-manager/blob/master/CHANGELOG.md) and prefixed by *[TODO DEPLOY]*. 
They are also present in the [release pages](https://github.com/LaCasemate/fab-manager/releases).

They execute specific tasks so they can't be automatic and have to be run by hand.

7. restart all containers

```bash
  docker-compose down
  docker-compose up -d
```

You can check that all containers are running with `docker ps`.

<a id="good-to-know"></a>
### Good to know

#### Is it possible to update several versions at the same time ?

Yes, indeed. It's the default behaviour as `docker-compose pull` command will fetch the latest versions of the docker images. 
Be sure to run all the specific commands listed in the [CHANGELOG](https://github.com/LaCasemate/fab-manager/blob/master/CHANGELOG.md) between your actual
and the new version in sequential order. (Example: to update from 2.4.0 to 2.4.3, you will run the specific commands for the 2.4.1, then for the 2.4.2 and then for the 2.4.3).