# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.191.1/containers/ruby/.devcontainer/base.Dockerfile

# [Choice] Ruby version: 3, 3.0, 2, 2.7, 2.6
ARG VARIANT="3"
FROM mcr.microsoft.com/devcontainers/ruby:${VARIANT}

# TinyTDS
RUN apt-get -y install libc6-dev \
    && wget http://www.freetds.org/files/stable/freetds-1.4.14.tar.gz \
    && tar -xzf freetds-1.4.14.tar.gz \
    && cd freetds-1.4.14 \
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

# Add the SQL Server main Gemfile and install the gems.
RUN mkdir -p /tmp/activerecord-sqlserver-adapter
COPY Gemfile VERSION activerecord-sqlserver-adapter.gemspec /tmp/activerecord-sqlserver-adapter/
RUN cd /tmp/activerecord-sqlserver-adapter \
    && bundle install \
    && rm -rf /tmp/activerecord-sqlserver-adapter
RUN chown -R vscode:vscode /usr/local/rvm
