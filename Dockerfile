FROM node:14-alpine

# DB
ENV PGDATA /var/lib/postgresql/data

RUN apk update && \
    apk add su-exec tzdata libpq postgresql postgresql-contrib postgresql-url_encode  && \
    mkdir /docker-entrypoint-initdb.d && \
    rm -rf /var/cache/apk/*

VOLUME /var/lib/postgresql/data

COPY files/docker-entrypoint.sh /

RUN chmod -R 755 /docker-entrypoint.sh && \
    mkdir -p /run/postgresql && \
    chown postgres: /run/postgresql && \
    mkdir -p /etc/postgres.db && \
    chown postgres: /etc/postgres.db

ENTRYPOINT ["/docker-entrypoint.sh"]

ADD ktpjs/ /var/lib/ktpjs/

WORKDIR /var/lib/ktpjs/bin

EXPOSE 8020
EXPOSE 8021
EXPOSE 8022
CMD ["DATABASE_URL=postgres://postgres@localhost/ktp node /var/lib/ktpjs/bin/ktp"]