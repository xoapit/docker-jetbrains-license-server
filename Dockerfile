ARG JLS_VERSION=26301
ARG JLS_SHA256=982c185aac91035463d89831ef82ba7fda400fe603d5598584b77986c459a66b

FROM --platform=${TARGETPLATFORM:-linux/amd64} crazymax/gosu:latest AS gosu
FROM --platform=${TARGETPLATFORM:-linux/amd64} adoptopenjdk:15-jre-hotspot
LABEL maintainer="CrazyMax"

ENV JLS_PATH="/opt/jetbrains-license-server" \
  TZ="UTC" \
  PUID="1000" \
  PGID="1000"

ARG JLS_SHA256
RUN apt-get update \
  && apt-get install -y \
    bash \
    curl \
    zip \
    tzdata \
  && mkdir -p /data "$JLS_PATH" \
  && curl -L "https://download.jetbrains.com/lcsrv/license-server-installer.zip" -o "/tmp/jls.zip" \
  && echo "$JLS_SHA256  /tmp/jls.zip" | sha256sum -c - | grep OK \
  && unzip "/tmp/jls.zip" -d "$JLS_PATH" \
  && rm -f "/tmp/jls.zip" \
  && chmod a+x "$JLS_PATH/bin/license-server.sh" \
  && ln -sf "$JLS_PATH/bin/license-server.sh" "/usr/local/bin/license-server" \
  && groupadd -f -g ${PGID} jls \
  && useradd -o -s /bin/bash -d /data -u ${PUID} -g jls -m jls \
  && chown -R jls. /data "$JLS_PATH" \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=gosu / /
COPY entrypoint.sh /entrypoint.sh

EXPOSE 8000
WORKDIR /data
VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/usr/local/bin/license-server", "run" ]

HEALTHCHECK --interval=10s --timeout=5s \
  CMD license-server status || exit 1
