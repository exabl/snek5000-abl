#!/usr/bin/env python
"""Make a simulation of with solver abl."""
import sys

import click
from abl.solver import Simul
from snek5000.log import logger


@click.group()
@click.option("-d", "--sub-dir", default="test")
@click.option("-m", "--mesh", default=1, type=int, help="mesh configuration")
@click.option("-n", "--name-run", default="demo", help="short description of the run")
@click.option("-o", "--nodes", default=1, type=int, help="number of nodes")
@click.option("-w", "--walltime", default="30:00")
@click.option("-zw", "--z-wall", default=0.0, type=float, help="wall position")
@click.option(
    "-fw", "--filter-weight", default=12, type=float, help="filter weight parameter",
)
@click.option(
    "-fc", "--filter-cutoff", default=0.5, type=float, help="filter cutoff ratio"
)
@click.pass_context
def cli(
    ctx, sub_dir, mesh, name_run, nodes, walltime, z_wall, filter_weight, filter_cutoff
):
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
    elif M == 11:
        oper.nx = 4
        oper.ny = 32
        oper.nz = 4
        oper.coords_y = (
            "0.1 5.4 11.6 18.7 26.8 36 46.5 58.5 72 87.5 105 125 147 173 201 "
            "233 269 310 354 404 458 518 583 654 731 812 900 991 1088 1187 "
            "1290 1394 1500"
        )
    elif M == 12:
        oper.nx = 4
        oper.ny = 20
        oper.nz = 4
        oper.coords_y = (
            "0.1 34.6 72.8 115. 161. 211. 266. 326. 390. 459. 534. 613. 697. "
            "786. 879. 976. 1076. 1180. 1285. 1392. 1500."
        )

    if M < 10:
        oper.origin_y = z_wall
        oper.Lx = 1280
        oper.Ly = 1500
        oper.Lz = 1280
    elif M < 20:
        oper.origin_y = float(oper.coords_y.split()[0])
        oper.Lx = 640
        oper.Ly = 1500
        oper.Lz = 640

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
        3: 5.0,  # Geostrophic velocity
        4: -1.4e-4,  # Coriolis frequency at 73 S
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
    params.nek.stat.av_step = 15
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
@click.argument("rule", default="srun")
@click.pass_context
def launch(ctx, rule):
    logger.info("Initializing simulation launch...")

    sim = Simul(ctx.obj["params"])
    sim.sanity_check()
    sim.make.exec([rule])
    if rule == "release":
        import shutil
        from setuptools_scm.git import GitWorkdir

        wd = GitWorkdir.from_potential_worktree("..")
        branch = wd.get_branch().replace("/", "-")
        version = wd.do_ex("git describe --tags")[0]
        output = f"abl_{version}_{branch}.tar.gz"

        logger.info(f"Release: {output}")
        shutil.move(sim.path_run / "abl-release.tar.gz", output)

    return sim


@cli.command()
@click.argument("rule", default="srun")
@click.pass_context
def debug(ctx, rule):
    import os
    import matplotlib.pyplot as plt
    from pymech.dataset import open_dataset

    os.environ["SNEK_DEBUG"] = "true"

    params = ctx.obj["params"]
    general = params.nek.general
    general.stop_at = "num_steps"
    general.num_steps = 10

    logger.info("Initializing simulation debug...")

    sim = Simul(params)
    sim.sanity_check()
    logger.info("Executing simulation...")
    sim.make.exec([rule])
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
        from abl.operators import OperatorsABL
        from abl import templates

        oper = OperatorsABL(params=params)
        template = getattr(templates, file)
        write_to_stdout = getattr(oper, f"write_{file}")
        write_to_stdout(template)
    else:
        raise ValueError(
            "The CLI argument file should be one of {'xml', 'par', 'size', 'box'}"
        )


if __name__ == "__main__":
    print(sys.executable)
    cli(obj={})
