#!/usr/bin/env bash

set -x
set -e

if [ -z "$FREETDS_VERSION" ]; then
  FREETDS_VERSION=$(ruby -r "./ext/tiny_tds/extconsts.rb" -e "puts FREETDS_VERSION")
fi

wget http://www.freetds.org/files/stable/freetds-$FREETDS_VERSION.tar.gz
tar -xzf freetds-$FREETDS_VERSION.tar.gz
cd freetds-$FREETDS_VERSION
./configure
make
sudo make install
cd ..
rm -rf freetds-$FREETDS_VERSION
rm freetds-$FREETDS_VERSION.tar.gz
