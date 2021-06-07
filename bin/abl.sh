#!/bin/bash
set -eu
CASE=mixing_len:with_penalty; ROUGH="0.0001"
# CASE=mixing_len:no_penalty; ROUGH="0.0001"

abl -d mixing_len -c $CASE -n penalty -o 1 -w 7-00:00:00 --in-place False \
  -s mixing_len \
  -b noslip \
  -zw $ROUGH -z0 $ROUGH \
  -p -1e-7 \
  $*
