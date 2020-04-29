import sys
import itertools

from eturb.clusters import Cluster


cluster = Cluster()
name_run = "neutral"
snakemake_rules = "srun"
dry_run = True

for mesh_nb_nodes, walltime, filter_weight, filter_cutoff in itertools.product(
    zip([1, 2, 3], [1, 1, 2]), ["23:00:00"], [0.25, 0.1, 0.03], [0.75]
):
    mesh, nb_nodes = mesh_nb_nodes
    cmd = (
        f"{sys.executable} ./simple.py "
        f"-n {name_run} -w {mesh} -fw {filter_weight} -fc {filter_cutoff} "
        f"{snakemake_rules}"
        f" > ../docs/journal/maronga/run_w{mesh}_fw{float(filter_weight)}_fc{filter_cutoff}.log;"
    )
    if dry_run:
        print(cmd)
#         print(f"nb_nodes = {nb_nodes}")
    else:
        cluster.submit_command(
            nb_nodes=nb_nodes,
            command=cmd,
            name_run=name_run,
            # walltime='7-00:00:00',
            # walltime="06:00:00",
            signal_num=False,
            walltime=walltime,
            requeue=True,
            ask=True,
            bash=False,
            email="avmo@misu.su.se",
            interactive=True,
            omp_num_threads=None,  # do not set
        )
