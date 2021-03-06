# Build the Target Server
FROM ravenx8/ubuntu-dev as build
WORKDIR /opt

RUN git clone https://github.com/dev-osrose/osIROSE-new.git /opt/osIROSE-new-src && \
    cd osIROSE-new-src && \
    git submodule update --init --recursive && \
    chmod -R 777 /opt/osIROSE-new-src/cmake/scripts/

WORKDIR /opt
RUN mkdir osIROSE-new-build && cd osIROSE-new-build && cmake -DOFFICIAL_BUILD=ON /opt/osIROSE-new-src \
    && cmake --build . --config ${build_config:-Release} \
    && mkdir /opt/osirose \
    && cp -r /opt/osIROSE-new-build/3rdparty/**/*.so* /opt/osirose \
    && cp -r /opt/osIROSE-new-build/bin/* /opt/osirose \
    && rm -r /opt/osirose/symbols \
    && cp /opt/osIROSE-new-src/cmake/scripts/docker_start_server.sh /opt/osirose/start.sh \
    && chmod -R 777 /opt/osirose/

# Run the final output
FROM ubuntu:rolling as char-server
COPY --from=build /opt/osirose/ /opt/osirose/

RUN apt-get update && apt-get install -y libmysqlclient-dev libcurl4-gnutls-dev

ARG CONFIG_FILE=/srv/osirose/server.json
ARG SERVER=CharServer

ENV CONFIG_FILE $CONFIG_FILE
ENV SERVER $SERVER
ENV LISTEN_IP "`ip a show eth0 | grep -Po 'inet \K[\d.]+'`"
ENV EXTERNAL_IP "`ip a show eth0 | grep -Po 'inet \K[\d.]+'`"

VOLUME ["/opt/osirose/scripts"]
VOLUME ["/srv/osirose"]

# Default Server client port
EXPOSE 29100/tcp

# Default ISC Server port
EXPOSE 29110/tcp

WORKDIR /opt/osirose
ENTRYPOINT [ "/opt/osirose/start.sh" ]