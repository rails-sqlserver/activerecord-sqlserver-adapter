FROM mcr.microsoft.com/devcontainers/ruby:2.7

# Install the SQL Server command-line tools and the Artistic Style code formatter
RUN curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc \
    && curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y astyle mssql-tools18 unixodbc-dev
ENV PATH=$PATH:/opt/mssql-tools18/bin

# Install FreeTDS
ENV FREETDS_VERSION=1.5.1
COPY test/bin/install-freetds.sh /tmp/
RUN /tmp/install-freetds.sh

# Add the tiny_tds main Gemfile and install the gems.
RUN mkdir -p /tmp/tiny_tds
COPY Gemfile VERSION tiny_tds.gemspec /tmp/tiny_tds/
RUN cd /tmp/tiny_tds \
    && bundle install \
    && rm -rf /tmp/tiny_tds
RUN chown -R vscode:vscode /usr/local/rvm && chown -R vscode:vscode /usr/local/bundle
