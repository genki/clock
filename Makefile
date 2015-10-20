test: clock.cr
	crystal build clock.cr
	./clock alerm

docker: Dockerfile
	docker build -t s21g/clock . | tee /dev/stdout | tail -n 1 \
		| sed -E "s/^Successfully built //" > CID

run:
	docker run --rm -it --entrypoint sh `cat CID`
