FROM ubuntu:latest
MAINTAINER David GUENAULT

ENV     GITBRANCH dev 

# base os upgrade
RUN     apt-get -y update && \
        apt-get -y upgrade

# prerequisites
RUN     apt-get -y install git-core libpq-dev redis-server imagemagick npm vim-nox postgresql sudo curl

RUN     apt-get -y install  build-essential openssl libreadline6 libreadline6-dev zlib1g zlib1g-dev \
        libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf \
        libc6-dev ncurses-dev automake libtool bison subversion 

# create a setup entry in sudo to gain root privilege without password
RUN     cp /etc/sudoers /etc/sudoers.orig && \
        groupadd setup && \
        echo "%setup ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/setup 

# create user and add it to group setup (gain privilege for everything in setup mode)
RUN     mkdir -p /home/fabmanager && \
        useradd fabmanager && \
        chown fabmanager:fabmanager /home/fabmanager && \
        usermod -a -G setup fabmanager 

# install rvm
RUN     su - fabmanager -c "cd /home/fabmanager && \
            gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && \
            curl -sSL https://get.rvm.io | bash -s stable --rails" 

# install dev env
RUN     chsh -s /bin/bash fabmanager && \
        su - fabmanager -c "cd /home/fabmanager && \
        git clone https://github.com/LaCasemate/fab-manager.git && \
        git checkout $GITBRANCH
        cd /home/fabmanager/fab-manager && \
        mkdir -p /home/fabmanager/fab-manager/tmp/pids && \
        rvm current && \
        bundle install"  
 
# remove privileges
RUN     usermod -G fabmanager fabmanager

# make default template unicode compatible
RUN     /etc/init.d/postgresql start && \
        su - postgres -c "psql -c \"UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'template1';\"" && \
        su - postgres -c "psql -c \"DROP DATABASE template1;\"" && \
        su - postgres -c "psql -c \"CREATE DATABASE template1 WITH TEMPLATE = template0 ENCODING = 'UNICODE';\"" && \
        su - postgres -c "psql -c \"UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template1';\"" && \
        su - postgres -c "psql -d template1 -c \"VACUUM FREEZE\"" && \
        /etc/init.d/postgresql stop

# prepare database
RUN     /etc/init.d/postgresql start && \
        /etc/init.d/redis-server start && \
        su - postgres -c "psql -c \"CREATE USER fabmanager WITH ENCRYPTED PASSWORD 'fabmanager';\"" && \
        su - postgres -c "psql -c \"ALTER ROLE fabmanager WITH CREATEDB;\"" && \
        su - postgres -c "psql -c \"CREATE DATABASE fabmanager_development OWNER fabmanager;\"" && \
        su - postgres -c "psql -c \"CREATE DATABASE fabmanager_production OWNER fabmanager;\"" && \
        cd /home/fabmanager/fab-manager/config && \
        cp database.yml.default database.yml && \
        sed -i "s/sleede/fabmanager/g" /home/fabmanager/fab-manager/config/database.yml && \
        /etc/init.d/postgresql stop

# setup database
RUN     /etc/init.d/postgresql start && \
        /etc/init.d/redis-server start && \
        su -l fabmanager -s /bin/bash -c "cd /home/fabmanager/fab-manager && \
            rake db:setup" && \
        /etc/init.d/postgresql stop && \
        /etc/init.d/redis-server stop

# install supervisor
RUN     apt-get -y install supervisor && \
        sed -i "s/\(\$PORT\)/3000 -b 0.0.0.0/g" /home/fabmanager/fab-manager/Procfile

# make redis run foreground
RUN     sed -i "s/daemonize yes/daemonize no/g" /etc/redis/redis.conf

ADD     fabmanager.conf /etc/supervisor/conf.d/fabmanager.conf

CMD     ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

