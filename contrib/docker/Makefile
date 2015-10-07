DOCKER=/usr/bin/docker
COMPOSE=/usr/local/bin/docker-compose
COMPOSEFILE=fabmanager.yml
REPOSITORY=fabmanager
IMAGE=fabmanager
TAG=latest
IMAGENAME=$(REPOSITORY)/$(IMAGE):$(TAG)
CONTAINERNAME=fabmanager

build:
	@$(DOCKER) build -t $(IMAGENAME) .

interactive:
	@$(DOCKER) run -ti --rm $(IMAGENAME) /bin/bash

up:
	@$(COMPOSE)  -f $(COMPOSEFILE) up -d

ps:
	@$(COMPOSE)  -f $(COMPOSEFILE) ps

stop:
	@$(COMPOSE)  -f $(COMPOSEFILE) stop

start:
	@$(COMPOSE)  -f $(COMPOSEFILE) start

kill:
	@$(COMPOSE)  -f $(COMPOSEFILE) kill

rm:
	@$(COMPOSE)  -f $(COMPOSEFILE) rm -v --force

