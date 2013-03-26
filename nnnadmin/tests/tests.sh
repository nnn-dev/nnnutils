#!/bin/sh

if [ "$#" -eq '0' ]; then
 $(dirname $0)/../launch.sh -M $(dirname $0)/tests-modules -A allsys launch
else
 $(dirname $0)/../launch.sh -M $(dirname $0)/tests-modules "$@"
fi

