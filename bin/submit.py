#!/usr/bin/env python
import itertools
import sys

from snek5000.clusters import Cluster

cluster = Cluster()
sub_dir = "maronga"
name_run = "neutral-high-order"
sub_command = "debug"
dry_run = False

for mesh_nb_nodes_walltime, filter_weight, filter_cutoff in itertools.product(
    zip([1, 2, 3], [1, 1, 2], [f"{days}-00:00:00" for days in (2, 4, 7)]),
    [0.1],
    [0.75],
):
    mesh, nb_nodes, walltime = mesh_nb_nodes_walltime
    cmd = (
        f"\n{sys.executable} ./simple.py "
        f"-d {sub_dir} -m {mesh} -n {name_run} -o {nb_nodes} -w {walltime} "
        f"-fw {filter_weight} -fc {filter_cutoff} "
        f"{sub_command}"
    )
    if dry_run:
        print(cmd)
    else:
        cluster.submit_command(
            nb_nodes=nb_nodes,
            command=cmd,
            name_run=name_run,
            signal_num=False,
            walltime=walltime,
            requeue=True,
            ask=True,
            bash=False,
            email="avmo@misu.su.se",
            interactive=True,
            omp_num_threads=None,  # do not set
        )
