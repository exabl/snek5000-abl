#!/bin/bash
# MESH=11; ROUGH=0.1
# MESH=212; ROUGH=0.1
# MESH=222; ROUGH=0.0001
# MESH=12; ROUGH=0.0001
MESH=31; ROUGH="3.4289e-5"

abl -d penalty -m $MESH -n penalty -o 1 -w 7-00:00:00 --in-place False \
  -s channel_mixing_len \
  -b channel \
  -zw 0.0 -z0 $ROUGH \
  -p 1.0 \
  $@
