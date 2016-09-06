FROM ruby:2.3
MAINTAINER peng@sleede.com

# Install apt based dependencies required to run Rails as
# well as RubyGems. As the Ruby image itself is based on a
# Debian image, we use apt-get to install those.
RUN apt-get update && \
    apt-get install -y \
      nodejs \
      supervisor

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

# Run Bundle in a cache efficient way
WORKDIR /tmp
COPY Gemfile /tmp/
COPY Gemfile.lock /tmp/
RUN bundle install --binstubs

# Clean up APT when done.
#RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Web app
RUN mkdir -p /usr/src/app
RUN mkdir -p /usr/src/app/config
RUN mkdir -p /usr/src/app/invoices
RUN mkdir -p /usr/src/app/exports
RUN mkdir -p /usr/src/app/log
RUN mkdir -p /usr/src/app/public/uploads
RUN mkdir -p /usr/src/app/public/assets
RUN mkdir -p /usr/src/app/tmp/sockets
RUN mkdir -p /usr/src/app/tmp/pids

WORKDIR /usr/src/app

COPY docker/database.yml /usr/src/app/config/database.yml

COPY . /usr/src/app

# Volumes
VOLUME /usr/src/app/invoices
VOLUME /usr/src/app/exports
VOLUME /usr/src/app/public
VOLUME /usr/src/app/public/uploads
VOLUME /usr/src/app/public/assets
VOLUME /var/log/supervisor

# Expose port 3000 to the Docker host, so we can access it
# from the outside.
EXPOSE 3000

# The main command to run when the container starts. Also
# tell the Rails dev server to bind to all interfaces by
# default.
COPY docker/supervisor.conf /etc/supervisor/conf.d/fablab.conf
CMD ["/usr/bin/supervisord"]
