ARG IMAGE_VERSION=1.13-alpine

FROM elixir:${IMAGE_VERSION} AS builder

ENV MIX_ENV=prod
ARG PLEROMA_VER=v2.5.1

WORKDIR /build

RUN echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main" >> /etc/apk/repositories \
    && apk add git curl libmagic ncurses gcc g++ musl-dev make cmake file-dev tar

RUN curl https://git.pleroma.social/pleroma/pleroma/-/archive/${PLEROMA_VER}/pleroma-${PLEROMA_VER}.tar --output pleroma.tar && tar -xf pleroma.tar --strip-components 1 --directory /build

RUN mkdir -p /build/pleroma

RUN echo "import Mix.Config" > config/prod.secret.exs
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get --only prod
RUN mkdir release && mix release --path /build/pleroma

RUN cd pleroma && tar cvf pleroma.tar *

FROM elixir:${IMAGE_VERSION}

LABEL org.opencontainers.image.source https://github.com/resmo/pleroma-container
LABEL org.opencontainers.image.description Pleroma Container Image, elixir ${IMAGE_VERSION}, pleroma ${PLEROMA_VER}

ARG UID=1000
ARG GID=1000
ARG DATA=/var/lib/pleroma

ENV MIX_ENV=prod

RUN addgroup -g ${GID} pleroma \
    && adduser -h ${DATA} -s /bin/false -D -G pleroma -u ${UID} pleroma

RUN echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main" >> /etc/apk/repositories \
    && apk update \
    && apk add postgresql-client \
    exiftool imagemagick libmagic ffmpeg bash \
    openssl-dev

RUN mkdir -p /etc/pleroma \
    && mkdir -p ${DATA}/uploads \
    && mkdir -p ${DATA}/static

WORKDIR ${DATA}

COPY --from=builder /build/pleroma/pleroma.tar /tmp/pleroma.tar
RUN tar xvf /tmp/pleroma.tar && rm /tmp/pleroma.tar && chown -R pleroma ${DATA}

COPY ./entrypoint.sh /entrypoint.sh
COPY ./config.exs /etc/pleroma/config.exs

USER pleroma
EXPOSE 4000

ENTRYPOINT [ "/entrypoint.sh" ]
