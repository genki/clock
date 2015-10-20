build: clock.cr
	crystal build clock.cr --cross-compile "Linux x86_64" \
		--target "x86_64-unknown-linux-gnu" --release --single-module
docker: build Dockerfile
	docker build .
