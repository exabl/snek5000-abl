#!/usr/bin/env python
"""Make a simulation of with solver abl."""
from math import pi
import sys
print(sys.executable)

import click
from eturb.solvers.abl import Simul


@click.command()
@click.option(
    "-n",
    "--name-run",
    default="demo",
    type=str,
    help="short description of the run",
)
@click.option(
    "-w",
    "--weak-scaling",
    default=1,
    type=int,
    help="weak scaling factor to scale up the problem",
)
@click.argument("rules", nargs=-1, type=click.UNPROCESSED)
def launch(name_run, weak_scaling, rules):
    """\b
    Notes
    -----
    - only LES model activated
    - no stratification / temperature field
    - no rotation

    """
    params = Simul.create_default_params()

    oper = params.oper

    # Nek5000: abl.box
    # ================
    N = weak_scaling  # or number of nodes
    oper.nx = 15 * N
    oper.ny = 24 * N
    oper.nz = 10 * N
    oper.Lx = pi
    oper.Ly = 1
    oper.Lz = pi / 2
    oper.boundary = "P P sh SYM P P".split()

    save_freq = 100

    # Nek5000: SIZE
    # ===============
    oper.elem.order = oper.elem.order_out = 8
    oper.elem.coef_dealiasing = 2 / 3
    # TODO: try Pn-Pn grid
    oper.elem.staggered = True
    # TODO: Try to see if it works without strange values in SIZE file
    oper.nproc_min = 4
    oper.nproc_max = 32 * N
    # TODO: why not 0? since temperature is not active
    oper.scalars = 1

    # oper.max.hist = 1000
    # oper.max.obj = 4
    # oper.max.scalars_cons = 1
    # oper.max.sessions = 1
    # oper.max.dim_proj = 20
    # oper.max.dim_krylow = 30
    # oper.max.order_time = 3
    # TODO: assess if SIZE parameters are correct.

    # Nek5000: abl.par
    # ================
    general = params.nek.general
    general.stop_at = (
        "num_steps"
        #  "end_time"
    )
    general.num_steps = max(18_000, save_freq)
    general.end_time = 25.0
    # Original value:
    # general.target_cfl = 0.8
    #  general.target_cfl = 0.3
    #  general.time_stepper = "BDF2"
    general.write_control = (
        "timeStep"
        # "runTime"
    )
    general.write_interval = save_freq * 5
    general.filtering = "hpfrt"
    #  general.filtering = None
    #  general.filter_weight = 12.0
    #  general.user_param03 = 1
    # Coriolis frequency
    general.user_params = {
        4: 1e-4,  # Coriolis frequency
        5: oper.Lx,
        6: oper.Ly,
        7: oper.Lz
    }

    #  pressure = params.nek.pressure
    #  velocity = params.nek.velocity

    # TODO: Why so?
    #  pressure.residual_proj = True
    #  velocity.residual_proj = False

    # FIXME: try reducing tolerance
    #  pressure.residual_tol = 1e-5
    #  velocity.residual_tol = 1e-8
    #
    #  reynolds_number = 1e10
    #  velocity.viscosity = -reynolds_number

    # KTH Toolbox
    # ===========
    # TODO!
    params.nek.chkpoint.chkp_interval = save_freq
    params.nek.stat.av_step = 1
    params.nek.stat.io_step = save_freq

    # Fluidsim parameters
    # ===================
    params.short_name_type_run = name_run
    params.output.sub_directory = "simple"

    print(params)
    sim = Simul(params)
    sim.sanity_check()
    sim.make.exec(rules)


if __name__ == "__main__":
    launch()
