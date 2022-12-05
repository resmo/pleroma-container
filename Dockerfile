ARG IMAGE_VERSION=1.14.2-alpine

FROM elixir:${IMAGE_VERSION} AS builder

ENV MIX_ENV=prod
ARG PLEROMA_VER=v2.4.5

WORKDIR /build

RUN echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main" >> /etc/apk/repositories \
    && apk add git curl libmagic ncurses gcc g++ musl-dev make cmake file-dev

RUN git clone --branch ${PLEROMA_VER} --depth 1 https://git.pleroma.social/pleroma/pleroma.git /build

RUN mkdir -p /build/pleroma

RUN echo "import Mix.Config" > config/prod.secret.exs \
    && mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get --only prod \
    && mkdir release \
    && mix release --path /build/pleroma

RUN cd pleroma && tar cvf pleroma.tar *

FROM elixir:${IMAGE_VERSION}

ARG UID=1000
ARG GID=1000
ARG DATA=/var/lib/pleroma

ENV MIX_ENV=prod

RUN addgroup -g ${GID} pleroma \
    && adduser -h ${DATA} -s /bin/false -D -G pleroma -u ${UID} pleroma

RUN echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main" >> /etc/apk/repositories \
    && apk update \
    && apk add postgresql-client \
    exiftool imagemagick libmagic ffmpeg

RUN mkdir -p /etc/pleroma \
    && mkdir -p ${DATA}/uploads \
    && mkdir -p ${DATA}/static

WORKDIR ${DATA}

COPY --from=builder /build/pleroma/pleroma.tar /tmp/pleroma.tar
RUN tar xvf /tmp/pleroma.tar && rm /tmp/pleroma.tar && chown -R pleroma ${DATA}

USER pleroma

COPY ./entrypoint.sh /entrypoint.sh
COPY ./config.exs /etc/pleroma/config.exs

EXPOSE 4000

ENTRYPOINT [ "/entrypoint.sh" ]
