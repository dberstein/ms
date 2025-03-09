IMAGE=ms:dev

.PHONY: build
build:
	@time docker build --progress=plain -t $(IMAGE) .

.PHONY: run
run: build
	@docker run --rm -it -p 8080:80 $(IMAGE)
