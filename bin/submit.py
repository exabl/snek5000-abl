import os
import sys

from fluiddyn.clusters.snic import Tetralith


name_run = os.path.splitext(sys.argv[4])[0]

class Cluster(Tetralith):
    default_project = "2019-1-2"


cluster = Cluster()

cluster.submit_script(
    nb_nodes=int(sys.argv[1]),
    nb_cores_per_node=int(sys.argv[2]),
    nb_runs=int(sys.argv[3]),
    path=' '.join(sys.argv[4:]),
    path_resume='./resume_from_path.py',
    name_run=name_run,
    walltime='7-00:00:00',
    # walltime='23:59:58',
    ask=True, bash=False,
    email='avmo@kth.se', interactive=True,
    omp_num_threads=None,  # do not set
)
