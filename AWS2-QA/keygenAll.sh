#!/bin/sh
# setup the env

keygenSSH.sh $PWD/ssh/

keygenTLS.sh $PWD/tls/

getLicenses.sh $PWD/ikey/
