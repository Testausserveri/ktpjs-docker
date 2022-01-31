FROM alpine as extract-ktpjs

RUN apk add --update p7zip

WORKDIR /tmp/

RUN wget https://static.abitti.fi/etcher-usb/ktp-etcher.zip -O ktp-etcher.zip &&\
    unzip ktp-etcher.zip -d ktp-etcher/ &&\
    rm ktp-etcher.zip &&\
    7z x ktp-etcher/ytl/ktp.img -aou -o./ktp-img/ &&\
    rm -rf ktp-etcher &&\
    FS=$(ls -S ktp-img | grep primary | head -1); echo $FS; 7z x ./ktp-img/$FS -aou -o./primary/ &&\
    rm -rf ktp-img &&\
    7z x primary/live/filesystem.squashfs -aou -o./filesystem/ &&\
    rm -rf primary


FROM node:14-alpine

# DB
ENV PGDATA /var/lib/postgresql/data

RUN apk update && \
    apk add su-exec tzdata libpq postgresql postgresql-contrib postgresql-url_encode  && \
    mkdir /docker-entrypoint-initdb.d && \
    rm -rf /var/cache/apk/*

VOLUME /var/lib/postgresql/data

COPY docker-entrypoint.sh /

RUN chmod -R 755 /docker-entrypoint.sh && \
    mkdir -p /run/postgresql && \
    chown postgres: /run/postgresql && \
    mkdir -p /etc/postgres.db && \
    chown postgres: /etc/postgres.db

ENTRYPOINT ["/docker-entrypoint.sh"]

COPY --from=extract-ktpjs /tmp/filesystem/var/lib/ktpjs /var/lib/ktpjs/

# Remove dependency depending on libsystemd
WORKDIR /var/lib/ktpjs/
RUN sed -i.bak '/notify/d' bin/* && sed -i.bak '/sd-notify/d' package.json


WORKDIR /var/lib/ktpjs/bin

EXPOSE 8020
EXPOSE 8021
EXPOSE 8022
CMD ["DATABASE_URL=postgres://postgres@localhost/ktp node /var/lib/ktpjs/bin/ktp"]