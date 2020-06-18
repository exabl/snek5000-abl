#!/usr/bin/env python
"""Make a simulation of with solver abl."""
import sys

import click
from abl.solver import Simul


@click.group()
@click.option("-d", "--sub-dir", default="test")
@click.option("-m", "--mesh", default=1, type=int, help="mesh configuration")
@click.option("-n", "--name-run", default="demo", help="short description of the run")
@click.option("-o", "--nodes", default=1, type=int, help="number of nodes")
@click.option("-w", "--walltime", default="30:00")
@click.option("-zw", "--z-wall", default=0., type=float, help="wall position")
@click.option(
    "-fw", "--filter-weight", default=12, type=float, help="filter weight parameter",
)
@click.option(
    "-fc", "--filter-cutoff", default=0.5, type=float, help="filter cutoff ratio"
)
@click.pass_context
def cli(ctx, sub_dir, mesh, name_run, nodes, walltime, z_wall, filter_weight, filter_cutoff):
    """\b
    Notes
    -----
    - only LES model activated
    - no stratification / temperature field

    """
    params = Simul.create_default_params()

    oper = params.oper

    # Nek5000: abl.box
    # ================
    M = mesh
    if M == 1:
        oper.nx = 6
        oper.ny = 20
        oper.nz = 6
    elif M == 2:
        oper.nx = 12
        oper.ny = 24
        oper.nz = 12
    elif M == 3:
        oper.nx = 24
        oper.ny = 48
        oper.nz = 24

    oper.origin_y = z_wall
    oper.Lx = 1280
    oper.Ly = 1500
    oper.Lz = 1280
    oper.boundary = "P P sh SYM P P".split()

    save_freq = 10_000

    # Nek5000: SIZE
    # ===============
    oper.elem.order = oper.elem.order_out = 8
    oper.elem.coef_dealiasing = 2 / 3
    # TODO: try Pn-Pn grid
    oper.elem.staggered = True
    # TODO: Try to see if it works without strange values in SIZE file
    oper.nproc_min = 4
    oper.nproc_max = 32 * nodes
    # NOTE: ldimt has to be at least 1
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

    # FIXME: temporarily short simulations for testing filters
    general.num_steps = max(10_000_000, save_freq)
    general.end_time = 25.0
    # Original value:
    # general.target_cfl = 0.8
    #  general.target_cfl = 0.3
    #  general.time_stepper = "BDF2"
    general.write_control = (
        "timeStep"
        # "runTime"
    )
    general.write_interval = save_freq * 2
    # general.write_double_precision = False

    general.filtering = "hpfrt"
    #  general.filtering = None
    general.filter_weight = filter_weight
    general.filter_cutoff_ratio = filter_cutoff
    general.user_params = {
        3: 1,  # dp/dx pressure gradient
        4: -1.39e-4,  # Coriolis frequency at 73 S
        5: oper.Lx,
        6: oper.Ly,
        7: oper.Lz,
    }

    pressure = params.nek.pressure
    #  velocity = params.nek.velocity

    # TODO: Why so?
    #  pressure.residual_proj = True
    #  velocity.residual_proj = False

    # NOTE: reducing pressure residual tolerance affects velocity divergence
    # TODO: check if w -> O(pressure.residual_tol)
    pressure.residual_tol = 1e-5
    #  velocity.residual_tol = 1e-8
    #
    #  reynolds_number = 1e10
    #  velocity.viscosity = -reynolds_number

    # KTH Toolbox
    # ===========
    # TODO!
    params.nek.chkpoint.chkp_interval = save_freq
    params.nek.stat.av_step = save_freq // 5
    params.nek.stat.io_step = save_freq
    params.nek.monitor.wall_time = walltime

    # Fluidsim parameters
    # ===================
    params.short_name_type_run = name_run
    params.output.sub_directory = sub_dir

    ctx.ensure_object(dict)

    if ctx.invoked_subcommand is None:
        print(params)
    else:
        ctx.obj["params"] = params


@cli.command()
@click.argument("rules", default=["srun"])
@click.pass_context
def launch(ctx, rules):
    from snek5000.log import logger

    logger.info("Initializing simulation launch...")

    sim = Simul(ctx.obj["params"])
    sim.sanity_check()
    sim.make.exec(rules)


@cli.command()
@click.argument("rules", default=["srun"])
@click.pass_context
def debug(ctx, rules):
    import matplotlib.pyplot as plt
    from pymech.dataset import open_dataset
    from snek5000.log import logger

    params = ctx.obj["params"]
    general = params.nek.general
    general.stop_at = "num_steps"
    general.num_steps = 10

    logger.info("Initializing simulation debug...")

    rules = ["srun"]

    sim = Simul(params)
    sim.sanity_check()
    logger.info("Executing simulation...")
    sim.make.exec(rules)
    logger.info("Finished simulation...")

    ds = open_dataset(sorted(sim.path_run.glob("abl0.f*"))[0])
    dsx = ds.isel(x=ds.x.size // 2)
    dsy = ds.isel(y=20)
    dsz = ds.isel(z=ds.z.size // 2)
    for ds_slice in dsx, dsy, dsz:
        ds_slice.ux.plot()
        plt.show()
    breakpoint()


@cli.command()
@click.argument("file", default="par")
@click.pass_context
def show(ctx, file):
    params = ctx.obj["params"]
    file = file.lower()

    if file == "par":
        params.nek._write_par()
    elif file == "xml":
        print(params)
    elif file in ("size", "box"):
        from snek5000.operators import Operators
        from abl import templates

        oper = Operators(params=params)
        template = getattr(templates, file)
        write_to_stdout = getattr(oper, f"write_{file}")
        write_to_stdout(template)
    else:
        raise ValueError("The CLI argument file should be one of {'xml', 'par', 'size', 'box'}")


if __name__ == "__main__":
    print(sys.executable)
    cli(obj={})
