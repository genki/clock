FROM ubuntu:14.04
MAINTAINER Genki Takiuchi <genki@s21g.com>

RUN \
	apt-key adv --keyserver keys.gnupg.net --recv-keys 09617FD37CC06B54 && \
	echo "deb http://dist.crystal-lang.org/apt crystal main" > \
		/etc/apt/sources.list.d/crystal.list && \
	apt-get update && \
	apt-get install -y crystal gcc pkg-config libssl-dev && \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /usr/local/src/clock
WORKDIR /usr/local/src/clock
COPY ./clock.cr ./
RUN crystal build --release --single-module clock.cr
RUN mv clock /usr/bin
WORKDIR /
RUN rm -rf /usr/local/src/*

ONBUILD COPY ./alerm /etc/alerm
ENTRYPOINT ["clock"]
CMD ["/etc/alerm"]
