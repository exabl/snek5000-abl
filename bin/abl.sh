#!/bin/bash
# MESH=11; ROUGH=0.1
# MESH=212; ROUGH=0.1
# MESH=222; ROUGH=0.0001
MESH=12; ROUGH=0.0001

abl -d penalty -m $MESH -n penalty -o 1 -w 7-00:00:00 --in-place True \
  -fw 0.05 -fc 0.75 -ft False -sb False \
  -s mixing_len \
  -b noslip \
  -zw $ROUGH -z0 $ROUGH \
  -p 0.0 \
  $@
