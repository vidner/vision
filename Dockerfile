FROM crystallang/crystal
WORKDIR /opt/
COPY . /opt/
RUN shards build
ENTRYPOINT [ "./bin/vision" ]

