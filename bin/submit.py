import sys
import itertools

from eturb.clusters import Cluster


cluster = Cluster()
name_run = "rot"
snakemake_rules = "srun"
dry_run = True

for mesh, walltime, filter_wt in itertools.product(
    [1, 2], ["15:00:00", "15:00:00"], [12, 120],
):
    cmd = (
        f"\n{sys.executable} ./simple.py -n {name_run} -w {mesh} -f {filter_wt} "
        f"{snakemake_rules}"
    )
    if dry_run:
        print(cmd)
    else:
        cluster.submit_command(
            nb_nodes=nb_nodes,
            command=cmd,
            name_run=name_run,
            # walltime='7-00:00:00',
            # walltime="06:00:00",
            signal_num=False,
            walltime=walltime,
            ask=True,
            bash=False,
            email="avmo@misu.su.se",
            interactive=True,
            omp_num_threads=None,  # do not set
        )
