#!/usr/bin/env python
from pathlib import Path

from fluiddyn.io import FLUIDDYN_PATH_SCRATCH
from abl.clusters import Cluster
from snek5000.log import logger
from snek5000.params import load_params
from snek5000.make import unlock
from snek5000.util.restart import get_status, load_for_restart, SnekRestartError

cluster = Cluster()
base_name_run = "2021-11-15"
snakemake_rules = "run_fg"
modify_params = False
dryrun = not True

subdir = Path(FLUIDDYN_PATH_SCRATCH) / "buoy_test_sponge"
for path in filter(
    lambda path: path.name
    not in [
        # exceptions
    ]
    and path.is_dir()
    and base_name_run in path.name,
    # and not (path / "abl.log").exists(),
    subdir.glob("abl*"),
):
    # Skip if locked
    status  = get_status(path)
    if status.code == 423:
        unlock(path)
        logger.error(f"Unlocking {path}: {status}")
        # continue

    if status.code >= 400:
        logger.error(f"{err} : Skipping...")
        # continue
    else:
        logger.info(f"OK {path}")

    params = load_params(path)

    name_run = path.name[-8:]
    # name_run = name_run[:name_run.index('_14x4x7')]

    if modify_params:
        logger.info("Modifying I/O parameters ...")
        params.nek.stat.av_step = 1000
        params.nek.stat.io_step = 1000
        params.nek.pressure.residual_tol = 1e-10
        params.nek.general.num_steps = 1000

    nb_nodes = 1 if params.oper.nx <= 18 else 2
    # nb_nodes = 3 if "24x48" in path.name else 1

    nproc = min(nb_nodes * cluster.nb_cores_per_node, params.oper.nproc_max)
    nb_nodes = nproc // cluster.nb_cores_per_node

    cmd = f"""
~/.conda/envs/snek/bin/python ./simul_restart.py {path}
"""
# ~/.conda/envs/snek/bin/python ./simul_restart.py {path}
# cd {path} && snakemake {snakemake_rules} -j all
# cd {path} && mpiexec -n {nproc} ./nek5000 > abl.log

    if dryrun:
        if list(path.glob("rs6*")):
            logger.info(
                "Has restart files... modified parameters will be written to abl.par"
            )

        print("name_run =", name_run)
        print("nb_nodes =", nb_nodes)
        print(cmd)
    else:
        if list(path.glob("rs6*")):
            logger.info("Has restart files... writing modified parameters to abl.par")
            try:
                params.nek._write_par(path / "abl.par")
            except NameError:
                logger.info("Parameters left as is.")
                pass

        cluster.submit_command(
            nb_nodes=nb_nodes,
            command=cmd,
            name_run=name_run,
            # walltime="7-00:00:00",
            walltime="23:00:00",
            signal_num=False,
            ask=False,
            bash=False,
            requeue=True,
            email="avmo@misu.su.se",
            interactive=False,
            omp_num_threads=None,  # do not set
        )
