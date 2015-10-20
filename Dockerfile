FROM alpine
MAINTAINER Genki Takiuchi <genki@s21g.com>

RUN apk add --update g++ make libevent-dev pcre-dev gc-dev \
	&& rm -rf /var/cache/apk/*

WORKDIR /usr/local/src
RUN wget http://www.xmailserver.org/pcl-1.12.tar.gz
RUN tar xzf pcl-1.12.tar.gz
WORKDIR pcl-1.12
RUN ./configure --prefix=/usr
RUN make
RUN make install

RUN mkdir -p /usr/local/src/clock
WORKDIR /usr/local/src/clock
COPY clock.o ./
COPY errno.c ./
RUN gcc -c errno.c -o errno.o
RUN gcc errno.o clock.o -o /clock \
	-rdynamic -levent -lc -lrt -lpcl -lpcre -lgc -lpthread -ldl

RUN rm -rf /usr/local/src/*
RUN apk del g++ make && rm -rf /var/cache/apk/*

ENTRYPOINT ["/clock"]
CMD ["/etc/alerm"]
