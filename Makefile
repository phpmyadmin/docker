DOCKER_REPO = phpmyadmin/phpmyadmin

.PHONY: all build build_nc run logs clean stop rm prune

all: build run logs

build:
	docker build -t ${DOCKER_REPO}:testing .

build_nc:
	docker build --no-cache=true -t ${DOCKER_REPO}:testing .

run:
	docker-compose -f docker-compose.testing.yml up -d

logs:
	docker-compose -f docker-compose.testing.yml logs

clean: stop rm prune

stop:
	docker-compose -f docker-compose.testing.yml stop

rm:
	docker-compose -f docker-compose.testing.yml rm

prune:
	docker rm `docker ps -q -a --filter status=exited`
	docker rmi `docker images -q --filter "dangling=true"`
