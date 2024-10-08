.PHONY: all
all: clean test docker

clean:
	docker image rm uberlint || true

test:

.PHONY: docker
docker:
	docker buildx create --name uberlint || true
	docker buildx build --builder uberlint --progress=plain --platform linux/amd64,linux/arm64/v8 -t uberlint .

push:
	docker buildx create --name uberlint || true
	docker buildx build --builder uberlint --progress=plain --platform linux/amd64,linux/arm64/v8 -t ilikejam/uberlint --push .
