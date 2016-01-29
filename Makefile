PREFIX=hectcastro

.PHONY: all build riak-cs-container start-cluster test-cluster stop-cluster

all: stop-cluster riak-cs-container start-cluster

build riak-cs-container:
	docker build --no-cache -t "${PREFIX}/riak-cs" .

start-cluster:
	DOCKER_RIAK_CS_HAPROXY=1 DOCKER_RIAK_CS_AUTOMATIC_CLUSTERING=1 DOCKER_RIAK_CS_CLUSTER_SIZE=5 ./bin/start-cluster.sh

test-cluster:
	./bin/test-cluster.sh

stop-cluster:
	./bin/stop-cluster.sh

get-cred:
	@echo "Access Key: "
	@docker exec $$(docker ps --format "{{.ID}}\t{{.Names}}" | grep riak-cs01 | cut -f1) egrep "admin.key" /etc/riak-cs/riak-cs.conf | cut -d' ' -f3
	@echo "Secret Key:"
	@docker exec $$(docker ps --format "{{.ID}}\t{{.Names}}" | grep riak-cs01 | cut -f1) egrep "admin.secret" /etc/riak-cs/riak-cs.conf | cut -d' ' -f3
