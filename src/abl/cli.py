#!/usr/bin/env python
"""Make a simulation of with solver abl."""
import sys
from importlib import import_module
from pathlib import Path
from pprint import pprint

import click

from abl.output import (
    avail_boundary_conds,
    avail_sgs_models,
    avail_temp_boundary_conds,
)
from abl.solver import Simul
from snek5000.log import logger


def apply_case(case, params):
    """Apply case specific parameters. See :mod:`abl.cases`"""
    module_name, _, func_name = case.partition(":")
    func_name = func_name or "_common"  # Default to _common if empty

    module = import_module(f".{module_name}", package="abl.cases")
    func = getattr(module, func_name)
    func(params)


@click.group(context_settings={"help_option_names": ("-h", "--help")})
@click.option("-d", "--sub-dir", default="test")
@click.option(
    "-c",
    "--case",
    default="default:do_nothing",
    type=str,
    help="case config (syntax: <module name under snek5000.cases>:<function>)",
)
@click.option("-n", "--name-run", default="demo", help="short description of the run")
@click.option("-o", "--nodes", default=1, type=int, help="number of nodes")
@click.option("-w", "--walltime", default="30:00")
@click.option("-i", "--in-place", default=False, type=bool, help="compile in place")
@click.option("-zw", "--z-wall", default=0.0, type=float, help="wall position")
@click.option("-z0", "--z-rough", default=0.1, type=float, help="roughness parameter")
@click.option(
    "-fw",
    "--filter-weight",
    default=0.05,
    type=float,
    help="filter weight parameter",
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
    "-bb",
    "--buoyancy-bottom",
    default="isotherm",
    type=click.Choice(avail_temp_boundary_conds),
    help="temperature boundary condition (bottom)",
)
@click.option(
    "-bt",
    "--buoyancy-top",
    default="isotherm",
    type=click.Choice(avail_temp_boundary_conds),
    help="temperature boundary condition (top)",
)
@click.option(
    "-ri",
    "--richardson",
    default=0.0,
    type=float,
    help="Richardson number (EXPERIMENTAL: requires scaling) for buoyancy forcing term",
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
    case,
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
    buoyancy_bottom,
    buoyancy_top,
    richardson,
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
    oper.origin_y = z_wall
    output = params.output

    output.sgs_model = sgs_model
    output.boundary_cond = boundary_cond
    output.buoyancy_bottom = buoyancy_bottom
    output.buoyancy_top = buoyancy_top

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

    problem_type = params.nek.problemtype
    problem_type.variable_properties = True

    if params.output.boundary_cond == "noslip":
        problem_type.stress_formulation = False
        params.oper.boundary = ["P", "P", "W", "SYM", "P", "P"]
    elif params.output.boundary_cond == "moeng":
        problem_type.stress_formulation = True
        params.oper.boundary = ["P", "P", "sh", "SYM", "P", "P"]
    elif params.output.boundary_cond == "channel":
        problem_type.stress_formulation = True
        params.oper.boundary = ["P", "P", "sh", "sh", "P", "P"]
    else:
        raise NotImplementedError("Stress formulation or not?")

    params.oper.boundary_scalars = ["P"] * 6

    for boundary, index in (("buoyancy_bottom", 2), ("buoyancy_top", 3)):
        if getattr(params.output, boundary) == "isotherm":
            params.oper.boundary_scalars[index] = "t"
        elif getattr(params.output, boundary) == "flux":
            params.oper.boundary_scalars[index] = "f"

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
        reynolds_number = 1e3
    elif params.output.boundary_cond == "channel":
        reynolds_number = 125_000
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
    assert pen_tiamp <= 0.0, f"Penalty amplitude {pen_tiamp} cannot be positive!"
    penalty = params.nek.penalty
    penalty.tiamp = pen_tiamp

    # Fluidsim parameters
    # ===================
    params.short_name_type_run = name_run
    params.output.sub_directory = sub_dir
    logger.info("params.compile_in_feature is ignored")
    #  params.compile_in_place = in_place

    # Case specific params
    # ====================
    apply_case(case, params)

    if params.output.boundary_cond == "noslip" and penalty.enabled:
        if any(spos <= z_wall for spos in (penalty.sposy01, penalty.sposy02)):
            logger.warning(
                "Ensure that the penalty regions are sufficiently away from the wall."
            )

    general.user_params.update(
        {
            5: oper.Lx,
            6: oper.Ly,
            7: oper.Lz,
            8: richardson,
        }
    )

    ctx.ensure_object(dict)

    if ctx.invoked_subcommand is None:
        print(params)
    else:
        ctx.obj["params"] = params


@cli.command()
@click.argument("rule", default="run_fg")
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
@click.argument("rule", default="run")
@click.pass_context
def debug(ctx, rule):
    import os

    # import matplotlib.pyplot as plt  # noqa
    # from pymech.dataset import open_dataset

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

    if not (files or stat_files):
        logger.error("Simulation produced no output files!")

    breakpoint()


_show_options = ("xml", "par", "size", "box", "makefile_usr", "config")


@cli.command()
@click.argument("file", default="par", type=click.Choice(_show_options))
@click.pass_context
def show(ctx, file):
    import yaml

    from abl import templates
    from abl.output import OutputABL as Output

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
