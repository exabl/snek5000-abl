try:
    from fluiddyn.clusters.snic import ClusterSNIC as Base
except ImportError as e:
    print(e)
    from fluiddyn.clusters.local import ClusterLocal as Base

import sys


class Cluster(Base):
    default_project = "snic2019-1-2"
    cmd_run = "_delete"
    cmd_run_interactive = "_delete"
    
    def _create_txt_launching_script(self, **kwargs):
        txt = super()._create_txt_launching_script(**kwargs)
        return "\n".join(
            [
                line for line in txt.splitlines()
                if not line.startswith("_delete")
            ]
        )


cluster = Cluster()
cluster.commands_setting_env += ["source ../activate.sh"]
name_run = "irrot"
snakemake_rules = "run"


for nb_nodes in [1, 2]:
    cmd = f"\n./simple.py -n {name_run} -w {nb_nodes} {snakemake_rules}"

    cluster.submit_command(
        nb_nodes=nb_nodes,
        command=cmd,
        name_run=name_run,
        # walltime='7-00:00:00',
        walltime="06:00:00",
        ask=True,
        bash=False,
        email="avmo@misu.su.se",
        interactive=True,
        omp_num_threads=None,  # do not set
    )
