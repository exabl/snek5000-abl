#!/usr/bin/env python
import itertools
import sys

from snek5000.clusters import Cluster

cluster = Cluster()
sub_dir = "maronga-august"
name_run = "bc-3rd"
# sub_command = "launch"
# sub_command = "launch compile"
sub_command = "launch release"
cluster.cmd_run = "echo"
# sub_command = "debug"
# sub_command = "show box"
dry_run = False

for mesh_nb_nodes_walltime, filter_weight, filter_cutoff, z_wall in itertools.product(
    zip([11], [1] * 1, [f"{days}-00:00:00" for days in (7,) * 1]),
    [0.05],
    [0.75],
    [0.1],
):
    mesh, nb_nodes, walltime = mesh_nb_nodes_walltime
    cmd = (
        f"\n{sys.executable} ./simul.py "
        f"-d {sub_dir} -m {mesh} -n {name_run} -o {nb_nodes} -w {walltime} "
        f"-fw {filter_weight} -fc {filter_cutoff} "
        f"-zw {z_wall} "
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

# ./simple.py -m 2 -n geert -o 1 -w 7-00:00:00 -zw 0 -fw 0.05 -fc 0.75 show size
