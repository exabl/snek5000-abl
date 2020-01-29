#!/usr/bin/env python
"""Make a simulation of with solver abl."""
from math import pi

import click
from eturb.solvers.abl import Simul


@click.command()
@click.option("-n", "--name-run", help="short description of the run")
def launch(name_run):
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
    N = 2
    oper.nx = 6 * N
    oper.ny = N
    oper.nz = 3 * N
    oper.Lx = 2 * pi
    oper.Ly = 1
    oper.Lz = pi
    oper.boundary = "P P sh SYM P P".split()

    # Nek5000: SIZE
    # ===============
    oper.elem.order = oper.elem.order_out = 8
    oper.elem.coef_dealiasing = 2 / 3
    # TODO: try Pn-Pn grid
    oper.elem.staggered = True
    # TODO: Try to see if it works without strange values in SIZE file
    # oper.nproc_min = 4
    # oper.nproc_max = 32
    # TODO: why not 0? since temperature is not active
    oper.scalars = 1

    # oper.max.hist = 1000
    # oper.max.obj = 4
    # oper.max.scalars_cons = 5
    # oper.max.sessions = 2
    # oper.max.dim_proj = 20
    # oper.max.dim_krylow = 30
    # oper.max.order_time = 3
    # TODO: assess if SIZE parameters are correct.

    # Nek5000: abl.par
    # ================
    general = params.nek.general
    general.stop_at = (
        # "num_steps"
        "end_time"
    )
    general.num_steps = 1
    general.end_time = 25.0
    # Original value:
    # general.target_cfl = 0.8
    general.target_cfl = 0.3
    general.time_stepper = "BDF2"
    general.write_control = (
        "time_step"
        # "run_time"
    )
    general.write_interval = 25
    general.filtering = "explicit"
    general.filter_weight = 12.0
    general.user_param03 = 1

    pressure = params.nek.pressure
    velocity = params.nek.velocity

    # TODO: Why so?
    pressure.residual_proj = True
    velocity.residual_proj = False

    # FIXME: try reducing tolerance
    pressure.residual_tol = 1e-5
    velocity.residual_tol = 1e-8

    reynolds_number = 1e10
    velocity.viscosity = -reynolds_number

    # Fluidsim parameters
    # ===================
    params.short_name_type_run = name_run
    params.output.sub_directory = "simple"

    print(params)
    sim = Simul(params)
    sim.make.exec()


if __name__ == "__main__":
    launch()
