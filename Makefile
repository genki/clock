test: clock.cr
	crystal build clock.cr
	./clock alerm

clock: clock.cr
	docker run --rm -v $(PWD):/mnt -w /mnt crystallang/crystal \
		crystal build --release --single-module ./clock.cr

docker: clock Dockerfile
	docker build -t s21g/clock . | tee /dev/stdout | tail -n 1 \
		| sed -E "s/^Successfully built //" > CID

run: 
	docker run --name clock-dev -e TZ=Asia/Tokyo -v $(PWD)/alerm:/etc/alerm --rm `cat CID`
