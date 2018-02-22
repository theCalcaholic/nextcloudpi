#!/usr/bin/env bash

cd $(dirname "$0")

source ./library.sh

cd ./nextcloudpi-config.d
source ./letsencrypt.form

echo $(form2json)