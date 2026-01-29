ICONV_VERSION = ENV["TINYTDS_ICONV_VERSION"] || "1.18"
ICONV_SOURCE_URI = "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-#{ICONV_VERSION}.tar.gz"

OPENSSL_VERSION = ENV["TINYTDS_OPENSSL_VERSION"] || "3.6.0"
OPENSSL_SOURCE_URI = "https://www.openssl.org/source/openssl-#{OPENSSL_VERSION}.tar.gz"

FREETDS_VERSION = ENV["TINYTDS_FREETDS_VERSION"] || "1.5.10"
FREETDS_SOURCE_URI = "http://www.freetds.org/files/stable/freetds-#{FREETDS_VERSION}.tar.bz2"
