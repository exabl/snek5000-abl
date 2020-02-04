import sys

from eturb.clusters import Cluster


cluster = Cluster()
name_run = "irrot"
snakemake_rules = "run"


for nb_nodes in [1, 2]:
    cmd = f"\n{sys.executable} ./simple.py -n {name_run} -w {nb_nodes} {snakemake_rules}"

    cluster.submit_command(
        nb_nodes=nb_nodes,
        command=cmd,
        name_run=name_run,
        # walltime='7-00:00:00',
        # walltime="06:00:00",
        walltime="06:00:00",
        ask=True,
        bash=False,
        email="avmo@misu.su.se",
        interactive=True,
        omp_num_threads=None,  # do not set
    )
