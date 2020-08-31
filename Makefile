DOCKER_REPO = phpmyadmin

.PHONY: all build run logs clean stop rm prune

all: build run logs

build: build-apache build-fpm build-fpm-alpine

build-apache:
	docker build ${DOCKER_FLAGS} -t ${DOCKER_REPO}:testing apache

build-fpm:
	docker build ${DOCKER_FLAGS} -t ${DOCKER_REPO}:testing-fpm fpm

build-fpm-alpine:
	docker build ${DOCKER_FLAGS} -t ${DOCKER_REPO}:testing-fpm-alpine fpm-alpine

run:
	docker-compose -f docker-compose.testing.yml up -d

run-tests:
	docker-compose exec phpmyadmin /test-docker.sh phpmyadmin_testing 80 phpmyadmin_testing_db

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
