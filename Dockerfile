FROM crystallang/crystal

COPY ./clock /usr/bin/clock
WORKDIR /
ONBUILD COPY ./alerm /etc/alerm
ENTRYPOINT ["clock"]
CMD ["/etc/alerm"]
