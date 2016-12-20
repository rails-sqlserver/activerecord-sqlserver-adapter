#!/usr/bin/env bash

set -x
set -e

OPENSSL_VERSION=1.0.2j

wget https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
tar -xzf openssl-$OPENSSL_VERSION.tar.gz
cd openssl-$OPENSSL_VERSION
./config --prefix=/opt/local
make
make install
cd ..
rm -rf openssl-$OPENSSL_VERSION
rm openssl-$OPENSSL_VERSION.tar.gz
