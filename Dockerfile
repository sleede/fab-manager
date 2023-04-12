FROM ruby:3.2.2-alpine
MAINTAINER contact@fab-manager.com

# Install upgrade system packages
RUN apk update && apk upgrade && \
# Install runtime apk dependencies
    apk add --update \
      bash \
      curl \
      nodejs \
      yarn \
      git \
      openssh \
      imagemagick \
      supervisor \
      tzdata \
      libc-dev \
      ruby-dev \
      zlib-dev \
      xz \
      xz-dev \
      postgresql-dev \
      postgresql-client \
      libxml2-dev \
      libxslt-dev \
      libsass-dev \
      libsass \
      libc6-compat \
      libidn-dev && \
# Install buildtime apk dependencies
    apk add --update --no-cache --virtual .build-deps \
      alpine-sdk \
      build-base \
      linux-headers \
      patch

# Fix bug: LoadError: Could not open library '/usr/local/bundle/gems/sassc-2.1.0-x86_64-linux/lib/sassc/libsass.so': Error loading shared library ld-linux-x86-64.so.2: No such file or directory (needed by /usr/local/bundle/gems/sassc-2.1.0-x86_64-linux/lib/sassc/libsass.so)
# add libsass-dev libsass libc6-compat and env below
ENV LD_LIBRARY_PATH=/lib64

RUN gem install bundler

# Throw error if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

# Install gems in a cache efficient way
WORKDIR /tmp
COPY Gemfile* /tmp/
RUN bundle config set --local without 'development test doc' && bundle install && bundle binstubs --all

# Prepare the application directories
RUN mkdir -p /var/log/supervisor && \
    mkdir -p /usr/src/app/tmp/sockets && \
    mkdir -p /usr/src/app/tmp/pids && \
    mkdir -p /usr/src/app/tmp/cache && \
    mkdir -p /usr/src/app/log && \
    mkdir -p /usr/src/app/node_modules && \
    mkdir -p /usr/src/app/public/api && \
    chmod -R a+w /usr/src/app && \
    chmod -R a+w /var/run

# Install Javascript packages
WORKDIR /usr/src/app
COPY package.json /usr/src/app/package.json
COPY yarn.lock /usr/src/app/yarn.lock
RUN yarn install

# Clean up build deps, cached packages and temp files
RUN apk del .build-deps && \
    yarn cache clean && \
    rm -rf /tmp/* \
           /var/tmp/* \
           /var/cache/apk/* \
           /usr/lib/ruby/gems/*/cache/* && \
    chmod -R a+w /usr/src/app/node_modules

# Copy source files
COPY docker/database.yml /usr/src/app/config/database.yml
COPY . /usr/src/app

# Volumes (the folders are created by setup.sh)
VOLUME /usr/src/app/invoices \
       /usr/src/app/payment_schedules \
       /usr/src/app/exports \
       /usr/src/app/imports \
       /usr/src/app/public \
       /usr/src/app/public/uploads \
       /usr/src/app/public/packs \
       /usr/src/app/accounting \
       /usr/src/app/supporting_document_files \
       /var/log/supervisor

# Expose port 3000 to the Docker host, so we can access it from the outside
EXPOSE 3000

# The main command to run when the container starts. Also tell the Rails server
# to bind to all interfaces by default.
COPY docker/supervisor.conf /etc/supervisor/conf.d/fabmanager.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/fabmanager.conf"]
