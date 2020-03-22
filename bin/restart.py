from eturb.clusters import Cluster
from eturb.util import prepare_for_restart
from eturb.log import logger

from fluiddyn.io import FLUIDDYN_PATH_SCRATCH
from pathlib import Path


cluster = Cluster()
name_run = "restart"
snakemake_rules = "srun"
dryrun = False

subdir = Path(FLUIDDYN_PATH_SCRATCH) / "simple"
for path in subdir.iterdir():
    try:
        params = prepare_for_restart(path)
    except IOError as e:
        logger.error(e)
        logger.warning("Skipping...")
        continue

    params.nek.stat.av_step = 1
    params.nek.stat.io_step = 1
    params.nek.general.num_steps = 1000
    params.nek._write_par(path / "abl.par")

    #  nb_nodes = 1 if params.oper.nx <= 15 else 2
    nb_nodes = 1 if "15x" in path.name else 2
    walltime = "01:00:00"

    cmd = f"""
cd {path}
mpiexec -n {nb_nodes*cluster.nb_cores_per_node} ./nek5000 > {Path.cwd() / ("SLURM." + name_run)}.${{SLURM_JOBID}}.stdout 2>&1

"""
    if dryrun:
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
            ask=False,
            bash=False,
            email="avmo@misu.su.se",
            interactive=False,
            omp_num_threads=None,  # do not set
        )
