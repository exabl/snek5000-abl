#!/bin/bash
set -eu
CASE=lee_moser:with_penalty; ROUGH="3.4289e-5"

abl -d channel_tests -c $CASE -n penalty -o 1 -w 7-00:00:00 --in-place False \
  -s channel_mixing_len \
  -b channel \
  -zw 0.0 -z0 $ROUGH \
  -p 1.0 \
  $@
