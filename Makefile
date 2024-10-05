.PHONY: all
all: clean test docker

clean:
	docker image rm uberlint || true

test:

.PHONY: docker
docker:
	docker build --progress=plain --rm -t uberlint .
