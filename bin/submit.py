#!/usr/bin/env python
import itertools
import sys

from snek5000.clusters import Cluster

cluster = Cluster()
sub_dir = "test-abl-cli"
base_name_run = "hi"
# sub_command = "launch"
# sub_command = "launch compile"
# sub_command = "launch release"
sub_command = "debug"
cluster.cmd_run = "echo"
# sub_command = "debug"
# sub_command = "show box"
dry_run = not False

for (
    mesh_nb_nodes,
    walltime,
    filter_weight,
    filter_cutoff,
    filter_temporal,
    sgs_model,
    sgs_boundary,
    z_wall,
    z_rough,
) in itertools.product(
    itertools.zip_longest([11, 21], [1], fillvalue=1),
    ["7-00:00:00"],
    [0.05, 12],
    [0.75],
    # [0.], [1.],
    [False],
    ["constant"],  # "vreman"], "shear_imp"],
    # "dynamic"],
    [False],
    [0.1],
    [0.1],
):
    mesh, nb_nodes = mesh_nb_nodes

    name_run = (
        f"{base_name_run}-{sgs_model}-ft{int(filter_temporal)}-sb{int(sgs_boundary)}"
    )
    if filter_temporal and sgs_boundary:
        print(f"skipping ... {name_run}")
        continue

    cmd = (
        f"\n{sys.executable} -m abl.cli "
        f"-d {sub_dir} -m {mesh} -n {name_run} -o {nb_nodes} -w {walltime} "
        f"-fw {filter_weight} -fc {filter_cutoff} -ft {filter_temporal} "
        f"-s {sgs_model} -sb {sgs_boundary} "
        f"-zw {z_wall} -z0 {z_rough} "
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
