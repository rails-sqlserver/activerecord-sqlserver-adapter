# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.191.1/containers/ruby/.devcontainer/base.Dockerfile

# [Choice] Ruby version: 3, 3.0, 2, 2.7, 2.6
ARG VARIANT="3"
FROM mcr.microsoft.com/devcontainers/ruby:${VARIANT}

# [Choice] Node.js version: none, lts/*, 16, 14, 12, 10
#ARG NODE_VERSION="lts/*"
#RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

# [Optional] Uncomment this section to install additional OS packages.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        mariadb-client libmariadb-dev \
        postgresql-client postgresql-contrib libpq-dev \
        ffmpeg mupdf mupdf-tools libvips poppler-utils


#apt-get -y install "$@" >/dev/null 2>&1 \


# TinyTDS
RUN apt-get -y install libc6-dev \
    && wget http://www.freetds.org/files/stable/freetds-1.1.32.tar.gz \
    && tar -xzf freetds-1.1.32.tar.gz \
    && cd freetds-1.1.32 \
    && ./configure --prefix=/usr/local --with-tdsver=7.3 \
    && make \
    && make install

# Install the SQL Server command-line tools
RUN curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc \
    && curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev \
    && echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc \
    && echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> /root/.bashrc


#ARG IMAGEMAGICK_VERSION="7.1.0-5"
#RUN wget -qO /tmp/im.tar.xz https://imagemagick.org/archive/releases/ImageMagick-$IMAGEMAGICK_VERSION.tar.xz \
#    && wget -qO /tmp/im.sig https://imagemagick.org/archive/releases/ImageMagick-$IMAGEMAGICK_VERSION.tar.xz.asc \
#    && gpg --batch --keyserver keyserver.ubuntu.com --recv 89AB63D48277377A \
#    && gpg --batch --verify /tmp/im.sig /tmp/im.tar.xz \
#    && tar xJf /tmp/im.tar.xz -C /tmp \
#    && cd /tmp/ImageMagick-$IMAGEMAGICK_VERSION \
#    && ./configure --with-rsvg && make -j 9 && make install \
#    && ldconfig /usr/local/lib \
#    && rm -rf /tmp/*

# Add the Rails main Gemfile and install the gems. This means the gem install can be done
# during build instead of on start. When a fork or branch has different gems, we still have an
# advantage due to caching of the other gems.
#RUN mkdir -p /tmp/rails
#COPY Gemfile Gemfile.lock RAILS_VERSION rails.gemspec package.json yarn.lock /tmp/rails/
#COPY actioncable/actioncable.gemspec /tmp/rails/actioncable/
#COPY actionmailbox/actionmailbox.gemspec /tmp/rails/actionmailbox/
#COPY actionmailer/actionmailer.gemspec /tmp/rails/actionmailer/
#COPY actionpack/actionpack.gemspec /tmp/rails/actionpack/
#COPY actiontext/actiontext.gemspec /tmp/rails/actiontext/
#COPY actionview/actionview.gemspec /tmp/rails/actionview/
#COPY activejob/activejob.gemspec /tmp/rails/activejob/
#COPY activemodel/activemodel.gemspec /tmp/rails/activemodel/
#COPY activerecord/activerecord.gemspec /tmp/rails/activerecord/
#COPY activestorage/activestorage.gemspec /tmp/rails/activestorage/
#COPY activesupport/activesupport.gemspec /tmp/rails/activesupport/
#COPY railties/railties.gemspec /tmp/rails/railties/
#RUN cd /tmp/rails \
#    && bundle install \
#    && yarn install \
#    && rm -rf /tmp/rails
#RUN chown -R vscode:vscode /usr/local/rvm

# Add the SQL Server main Gemfile and install the gems.
RUN mkdir -p /tmp/activerecord-sqlserver-adapter
COPY Gemfile VERSION activerecord-sqlserver-adapter.gemspec /tmp/activerecord-sqlserver-adapter/
RUN cd /tmp/activerecord-sqlserver-adapter \
    && bundle install \
    && rm -rf /tmp/activerecord-sqlserver-adapter
RUN chown -R vscode:vscode /usr/local/rvm
