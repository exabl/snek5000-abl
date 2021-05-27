#!/usr/bin/env python
import itertools
import sys

from snek5000.clusters import Cluster

cluster = Cluster()
sub_dir = "channel_tests"
base_name_run = "ch"
sub_command = "launch"
#  sub_command = "launch compile"
# sub_command = "launch release"; cluster.cmd_run = "echo"
# sub_command = "debug"
# sub_command = "show box"
dry_run = not True

for (
    mesh_nb_nodes_walltime,
    filter_weight,
    filter_cutoff,
    filter_temporal,
    sgs_boundary,
    sgs_model,
    boundary_cond,
    z_wall,
    z0,
    pen_tiamp,
) in itertools.product(
    # zip([222], [1] * 1, [f"{days}-00:00:00" for days in (1,) * 1]),
    zip([31], [2] * 1, ["03:00:00"]),
    [0.05],
    [0.75],
    # [0.], [1.],
    [False],
    [False],
    ["channel_mixing_len"],
    #  ["vreman", "constant", "shear_imp"],
    # "dynamic"],
    ["channel"],
    [0.000],
    [3.4289e-5],
    #  [-(10 ** p) for p in range(6)],
    [0],
):
    mesh, nb_nodes, walltime = mesh_nb_nodes_walltime

    name_run = f"{base_name_run}-{sgs_model}"  # "-{pen_tiamp:07d}"
    if filter_temporal and sgs_boundary:
        print(f"skipping ... {name_run}")
        continue

    cmd = (
        f"\n{sys.executable} -m abl.cli "
        f"-d {sub_dir} -m {mesh} -n {name_run} -o {nb_nodes} -w {walltime} "
        f"-fw {filter_weight} -fc {filter_cutoff} -ft {filter_temporal} "
        f"-s {sgs_model} -sb {sgs_boundary} "
        f"-b {boundary_cond} "
        f"-zw {z_wall} -z0 {z0} "
        f"-p {pen_tiamp} "
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
            # NOTE: for small simulations
            nb_cores_per_node=16,
        )
