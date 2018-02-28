#!/bin/bash

cd $(dirname $0)/platform-scripts
CONNECT=$(terraform output connect_string | sed 's/^.* = //')
cd ../data
exec $CONNECT
