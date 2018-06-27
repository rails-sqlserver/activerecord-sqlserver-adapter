FROM ruby:2.6-rc

RUN apt-get update && apt-get install -y \
  build-essential \
  imagemagick \
  libfontconfig1-dev \
  libssl-dev \
  libxml2-dev \
  libxslt-dev \
  pkg-config \
  less \
  wget \
  unzip

# Node.js
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get install -y nodejs

# yarn
# RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -\
#     && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
#     && apt-get update \
#     && apt-get install -y yarn
#
# RUN wget -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
#   && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
#   && apt-get update -y \
#   && apt-get -y install google-chrome-stable \
#   && rm /etc/apt/sources.list.d/google-chrome.list \
#   && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
#   && google-chrome --version
#
# RUN  wget --no-check-certificate https://chromedriver.storage.googleapis.com/2.38/chromedriver_linux64.zip \
#   && unzip chromedriver_linux64.zip \
#   && rm chromedriver_linux64.zip \
#   && mv -f chromedriver /usr/local/share/ \
#   && chmod +x /usr/local/share/chromedriver \
#   && ln -s /usr/local/share/chromedriver /usr/local/bin/chromedriver \
#   && chromedriver -v


# ADD ./package.json /wordsearch/package.json
# ADD ./yarn.lock /wordsearch/yarn.lock
# RUN yarn install

RUN cd /tmp

ADD ./test/bin /src/test/bin

RUN /src/test/bin/install-openssl.sh
# RUN /src/test/bin/install-freetds.sh

RUN wget http://www.freetds.org/files/stable/freetds-1.00.27.tar.gz
RUN tar -xzf freetds-1.00.27.tar.gz
RUN cd freetds-1.00.27
RUN ls
RUN ./freetds-1.00.27/configure --prefix=/usr/local --with-tdsver=7.3
RUN make install ./freetds-1.00.27


# RUN mkdir /src
WORKDIR /src
ADD ./Gemfile /src/Gemfile
ADD ./activerecord-sqlserver-adapter.gemspec /src/activerecord-sqlserver-adapter.gemspec
ADD ./lib/active_record/connection_adapters/sqlserver/version.rb /src/lib/active_record/connection_adapters/sqlserver/version.rb
ADD ./VERSION /src/VERSION
RUN bundle install --jobs=7
