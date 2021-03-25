#!/usr/bin/env python
"""Make a simulation of with solver abl."""
import sys
from math import pi
from pathlib import Path
from pprint import pprint

import click
from abl.output import avail_boundary_conds, avail_sgs_models
from abl.solver import Simul
from snek5000.log import logger


@click.group()
@click.option("-d", "--sub-dir", default="test")
@click.option("-m", "--mesh", default=11, type=int, help="mesh configuration")
@click.option("-n", "--name-run", default="demo", help="short description of the run")
@click.option("-o", "--nodes", default=1, type=int, help="number of nodes")
@click.option("-w", "--walltime", default="30:00")
@click.option("-i", "--in-place", default=False, type=bool, help="compile in place")
@click.option("-zw", "--z-wall", default=0.0, type=float, help="wall position")
@click.option("-z0", "--z-rough", default=0.1, type=float, help="roughness parameter")
@click.option(
    "-fw", "--filter-weight", default=0.05, type=float, help="filter weight parameter",
)
@click.option(
    "-fc", "--filter-cutoff", default=0.75, type=float, help="filter cutoff ratio"
)
@click.option(
    "-ft",
    "--filter-temporal",
    default=False,
    type=bool,
    help="turn on temporal filtering for boundary condition",
)
@click.option(
    "-b",
    "--boundary-cond",
    default="moeng",
    type=click.Choice(avail_boundary_conds),
    help="boundary condition",
)
@click.option(
    "-s",
    "--sgs-model",
    default="constant",
    type=click.Choice(avail_sgs_models),
    help="SGS models",
)
@click.option(
    "-sb",
    "--sgs-boundary",
    default=False,
    type=bool,
    help="Boundary condition for SGS models",
)
@click.option(
    "-p",
    "--pen-tiamp",
    default=0.0,
    type=float,
    help="penalty time independent amplitude",
)
@click.pass_context
def cli(
    ctx,
    sub_dir,
    mesh,
    name_run,
    nodes,
    walltime,
    in_place,
    z_wall,
    z_rough,
    filter_weight,
    filter_cutoff,
    filter_temporal,
    boundary_cond,
    sgs_model,
    sgs_boundary,
    pen_tiamp,
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
    elif M in (11, 111):
        oper.ny = 32
        oper.coords_y = (
            f"{z_wall} 5.4 11.6 18.7 26.8 36 46.5 58.5 72 87.5 105 125 147 173 201 "
            "233 269 310 354 404 458 518 583 654 731 812 900 991 1088 1187 "
            "1290 1394 1500"
        )
        if M == 11:
            oper.nx = oper.nz = 4
        elif M == 111:
            oper.nx = oper.nz = 8
    elif M in (12, 112, 212):
        oper.ny = 20
        oper.coords_y = (
            f"{z_wall} 34.6 72.8 115. 161. 211. 266. 326. 390. 459. 534. 613. 697. "
            "786. 879. 976. 1076. 1180. 1285. 1392. 1500."
        )
        if M == 12:
            oper.nx = oper.nz = 4
        elif M == 112:
            oper.nx = oper.nz = 8
        elif M == 212:
            oper.nx = oper.nz = 3
    elif M == 21:
        # Similar to M 11 - scaled by 1500
        oper.nx = 4
        oper.ny = 32
        oper.nz = 4
        oper.coords_y = (
            f"{z_wall} 0.0036 0.0077 0.0125 0.0179 0.0240 0.0310 0.0390 0.0480 "
            "0.0583 0.0700 0.0833 0.0980 0.1153 0.1340 0.1553 0.1793 0.2067 "
            "0.2360 0.2693 0.3053 0.3453 0.3887 0.4360 0.4873 0.5413 0.6000 "
            "0.6607 0.7253 0.7913 0.8600 0.9293 1.000"
        )
    elif M in (22, 122, 222):
        # Similar to M 12 - scaled by 1500
        oper.ny = 20
        oper.coords_y = (
            f"{z_wall} 0.0231 0.0485 0.0767 0.1073 0.1407 0.1773 0.2173 0.2600 "
            "0.3060 0.3560 0.4087 0.4647 0.5240 0.5860 0.6507 0.7173 0.7867 "
            "0.8567 0.9280 1.000"
        )
        if M == 22:
            oper.nx = oper.nz = 4
        elif M == 122:
            oper.nx = oper.nz = 8
        elif M == 222:
            oper.nx = 3
            oper.nz = 3
            # FIXME: try reducing it further
            # Now causes WARNINGb: Detected non-right-handed element and erros
            # See connect1.f line: 954

    if M <= 9:
        oper.origin_y = z_wall
        oper.Lx = 1280
        oper.Ly = 1500
        oper.Lz = 1280
    elif M % 100 <= 19:  # 11, 12, 111, 112, 212
        oper.origin_y = float(oper.coords_y.split()[0])
        oper.Lx = 640
        oper.Ly = 1500
        oper.Lz = 640
        if M == 212:
            oper.Lx = oper.Lz = 300
    elif M % 100 <= 29:  # 21, 22, 122, 222
        # Chatterjee & Peet:
        oper.origin_y = float(oper.coords_y.split()[0])
        oper.Ly = 1.0
        if M in (22, 122):
            oper.Lx = round(2 * pi, 4)
            oper.Lz = round(pi, 4)
        elif M == 222:
            oper.Lx = oper.Lz = 0.1

    oper.boundary = "P P sh SYM P P".split()

    save_freq = 1_000

    # Nek5000: SIZE
    # ===============
    oper.elem.order = oper.elem.order_out = 8
    oper.elem.coef_dealiasing = 2 / 3
    # TODO: try Pn-Pn grid
    oper.elem.staggered = True
    # TODO: Try to see if it works without strange values in SIZE file
    oper.nproc_min = 2
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

    # SGS and BC
    # ==========
    output = params.output

    output.sgs_model = sgs_model
    output.boundary_cond = boundary_cond
    # output.boundary_cond = "noslip"

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
    # TODO: try BDF3
    #  general.time_stepper = "BDF2"
    general.write_control = (
        "timeStep"
        # "runTime"
    )
    general.write_interval = save_freq * 2
    # general.write_double_precision = False

    if filter_weight == 0 or filter_cutoff == 1:
        general.filtering = None
    else:
        general.filtering = "hpfrt"
    general.filter_weight = filter_weight
    general.filter_cutoff_ratio = filter_cutoff
    general.user_params = {
        3: 5.0,
        4: 0.0014,
        5: oper.Lx,
        6: oper.Ly,
        7: oper.Lz,
    }

    problem_type = params.nek.problemtype
    problem_type.variable_properties = True

    if params.output.boundary_cond == "noslip":
        problem_type.stress_formulation = False
        params.oper.boundary = ["P", "P", "W", "SYM", "P", "P"]
    elif params.output.boundary_cond == "moeng":
        problem_type.stress_formulation = True
        params.oper.boundary = ["P", "P", "sh", "SYM", "P", "P"]
    else:
        raise NotImplementedError("Stress formulation or not?")

    pressure = params.nek.pressure
    velocity = params.nek.velocity

    # TODO: Why so?
    #  pressure.residual_proj = True
    #  velocity.residual_proj = False

    # NOTE: reducing pressure residual tolerance affects velocity divergence
    # TODO: check if w -> O(pressure.residual_tol)
    pressure.residual_tol = 1e-5
    velocity.residual_tol = 1e-8
    #
    if params.output.boundary_cond == "noslip":
        reynolds_number = 1e4
    else:
        reynolds_number = 1e10

        assert output.sgs_model != "mixing_len", "May not work with moeng and high Re!"

    velocity.viscosity = -reynolds_number

    # KTH Toolbox
    # ===========
    # TODO!
    params.nek.chkpoint.chkp_interval = save_freq
    params.nek.stat.av_step = 15
    params.nek.stat.io_step = save_freq
    params.nek.monitor.wall_time = walltime

    # WMLES parameters
    # ================
    wmles = params.nek.wmles
    wmles.bc_temp_filt = filter_temporal
    # wmles.bc_z_index = 3
    wmles.bc_z0 = z_rough
    wmles.sgs_delta_max = True
    # wmles.sgs_npow = 3.0
    wmles.sgs_c0 = 0.19
    wmles.sgs_bc = sgs_boundary

    # Flow phys parameters
    # ====================
    #  fp = params.nek.flow_phys
    #  fp.corio_on = False
    #  fp.u_geo = 1.0

    # Penalty parameters
    # ==================
    assert pen_tiamp >= 0.0, f"Penalty amplitude {pen_tiamp} should not be negative!"
    penalty = params.nek.penalty
    penalty.nregion = 1
    penalty.tiamp = pen_tiamp
    penalty.eposx01 = oper.Lx
    penalty.sposy01 = 0.05 * oper.Ly
    penalty.eposy01 = 0.3 * oper.Ly
    # float(oper.coords_y.split()[1])  # boundary of first element
    penalty.eposz01 = oper.Lz
    penalty.smthy01 = penalty.eposy01 - penalty.sposy01

    # Fluidsim parameters
    # ===================
    params.short_name_type_run = name_run
    params.output.sub_directory = sub_dir
    params.compile_in_place = in_place

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
    assert sim.make.exec([rule], scheduler="greedy")
    if rule == "release":
        import shutil
        from setuptools_scm.file_finder_git import _git_toplevel
        from setuptools_scm.git import GitWorkdir

        wd = GitWorkdir.from_potential_worktree(_git_toplevel(None))
        assert wd is not None, "Failed to obtain git work directory"
        branch = wd.get_branch().replace("/", "-")
        version = wd.do_ex("git describe --tags")[0]
        output = Path.cwd() / f"abl_{version}_{branch}.tar.gz"

        logger.info(f"Release: {output}")
        shutil.move(sim.path_run / "abl-release.tar.gz", output)

    return sim


@cli.command()
@click.argument("rule", default="srun")
@click.pass_context
def debug(ctx, rule):
    import os
    import matplotlib.pyplot as plt  # noqa
    from pymech.dataset import open_dataset

    os.environ["SNEK_DEBUG"] = "true"

    params = ctx.obj["params"]
    general = params.nek.general
    general.stop_at = "num_steps"
    general.num_steps = 21
    params.nek.stat.av_step = 2
    params.nek.stat.io_step = 20

    logger.info("Initializing simulation debug...")

    sim = Simul(params)
    logger.info("Executing simulation...")
    sim.make.exec([rule])
    logger.info("Finished simulation...")

    files = sorted(sim.path_run.glob("abl0.f*"))
    stat_files = sorted(sim.path_run.glob("stsabl0.f*"))
    if files:
        ds = open_dataset(files[-1])
        dsx = ds.isel(x=ds.x.size // 2)  # noqa
        dsy = ds.isel(y=20)  # noqa
        dsz = ds.isel(z=ds.z.size // 2)  # noqa
        #  for ds_slice in dsx, dsy, dsz:
        #      ds_slice.ux.plot()
        #      plt.show()
    if stat_files:
        ds_stat = open_dataset(stat_files[0])  # noqa

    if not (files or stat_files):
        logger.error("Simulation failed!")

    breakpoint()


_show_options = ("xml", "par", "size", "box", "makefile_usr", "config")


@cli.command()
@click.argument("file", default="par", type=click.Choice(_show_options))
@click.pass_context
def show(ctx, file):
    import yaml
    from abl.output import OutputABL as Output
    from abl import templates

    params = ctx.obj["params"]
    file = file.lower()

    if file == "par":
        params.nek._write_par()
    elif file == "xml":
        print(params)
    elif file == "config":
        with Output.get_configfile().open() as fp:
            config = yaml.safe_load(fp)
        pprint(config)
    elif file == "makefile_usr":
        output = Output(params=params)
        output.write_makefile_usr(templates.makefile_usr, sys.stdout)
    elif file in ("size", "box"):
        from abl.operators import OperatorsABL

        oper = OperatorsABL(params=params)
        template = getattr(templates, file)
        write_to_stdout = getattr(oper, f"write_{file}")
        write_to_stdout(template)
    else:
        raise ValueError(f"The CLI argument file should be one of {_show_options}")


def main():
    cli(obj={})


if __name__ == "__main__":
    main()
