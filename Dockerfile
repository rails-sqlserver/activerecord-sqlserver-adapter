ARG TARGET_VERSION=2.5.3

FROM wpolicarpo/activerecord-sqlserver-adapter:${TARGET_VERSION}

ENV WORKDIR /activerecord-sqlserver-adapter

RUN mkdir -p $WORKDIR
WORKDIR $WORKDIR

COPY . $WORKDIR

RUN bundle install --jobs `expr $(cat /proc/cpuinfo | grep -c "cpu cores") - 1` --retry 3

CMD ["sh"]
