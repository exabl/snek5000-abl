from pathlib import Path

from snek5000.clusters import Cluster
from snek5000.log import logger
from snek5000.util import prepare_for_restart
from fluiddyn.io import FLUIDDYN_PATH_SCRATCH

cluster = Cluster()
name_run = "restart"
snakemake_rules = "srun"
modify_params = False
dryrun = False

subdir = Path(FLUIDDYN_PATH_SCRATCH) / "maronga-june"
for path in filter(
    lambda path: path.name not in [
        "abl_neutral_12x24x12_V1280.x1500.x1280._2020-06-04_11-16-25"
    ],
    subdir.iterdir()
):
    try:
        params = prepare_for_restart(path)
    except IOError as err:
        logger.error(f"{err} : Skipping...")
        # continue
    else:
        logger.info(f"OK {path}")

    if modify_params:
        logger.info("Modifying I/O parameters ...")
        params.nek.stat.av_step = 1000
        params.nek.stat.io_step = 1000
        params.nek.pressure.residual_tol = 1e-10
        params.nek.general.num_steps = 1000

    #  nb_nodes = 1 if params.oper.nx <= 15 else 2
    nb_nodes = 2 if "24x48" in path.name else 1

    cmd = f"""
cd {path}
snakemake {snakemake_rules} -j
"""
    if dryrun:
        if list(path.glob("rs6*")):
            logger.info("Has restart files... modified parameters will be written to abl.par")

        print(cmd)
    else:
        if list(path.glob("rs6*")):
            logger.info("Has restart files... writing modified parameters to abl.par")
            params.nek._write_par(path / "abl.par")

        cluster.submit_command(
            nb_nodes=nb_nodes,
            command=cmd,
            name_run=name_run,
            walltime='7-00:00:00',
            # walltime="06:00:00",
            signal_num=False,
            ask=False,
            bash=False,
            email="avmo@misu.su.se",
            interactive=False,
            omp_num_threads=None,  # do not set
        )
