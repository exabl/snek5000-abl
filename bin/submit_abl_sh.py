#!/usr/bin/env python
import itertools
import sys

from snek5000.clusters import Cluster

cluster = Cluster()
sub_command = "launch"
sub_command = "launch compile"
# sub_command = "launch release"; cluster.cmd_run = "echo"
# sub_command = "debug"
# sub_command = "show box"

nb_nodes = 1
name_run = "abl.sh"
walltime = "06:00:00"
dry_run = True

for pen_amp in (-1e-6, -1e-7, -1e-8):
    cmd = f"./abl.sh -p {pen_amp} {sub_command}"

    if dry_run:
        print(cmd)
    else:
        cluster.submit_command(
            nb_nodes=nb_nodes,
            command="cmd",
            name_run=name_run,
            signal_num=False,
            walltime=walltime,
            requeue=True,
            ask=True,
            bash=False,
            email="avmo@misu.su.se",
            interactive=True,
            omp_num_threads=None,  # do not set
            # NOTE: for small simulations
            nb_cores_per_node=16,
        )
