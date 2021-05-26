"""A tower of spectral elements using the mixing length model
=============================================================

"""
from math import nan


def no_penalty(params):
    oper = params.oper

    oper.nx = 3
    oper.ny = 20
    oper.nz = 3

    oper.coords_y = (
        f"{oper.origin_y} 0.0231 0.0485 0.0767 0.1073 0.1407 0.1773 0.2173 0.2600 0.3060 "
        "0.3560 0.4087 0.4647 0.5240 0.5860 0.6507 0.7173 0.7867 0.8567 0.9280 "
        "1.000"
    )

    oper.Lx = 0.1
    oper.Ly = 1.0
    oper.Lz = 0.1

    general = params.nek.general

    general.stop_at = "num_steps"
    general.num_steps = 10_000_000

    general.variable_dt = True

    general.write_control = "timeStep"
    general.write_interval = 20_000

    general.filter_weight = 5.0
    general.filter_cutoff_ratio = nan
    general.filter_modes = 2
    general.user_params.update({3: 5.0, 4: 0.0014})

    reynolds_number = 10_000
    params.nek.velocity.viscosity = -reynolds_number

    params.nek.stat.av_step = 15
    params.nek.stat.io_step = 10_000

    params.nek.penalty.enabled = False


def with_penalty(params):
    # First populate common parameters
    no_penalty(params)

    oper = params.oper

    penalty = params.nek.penalty
    penalty.enabled = True
    penalty.nregion = 1
    penalty.eposx01 = oper.Lx
    penalty.sposy01 = oper.origin_y
    penalty.eposy01 = 0.1
    penalty.eposz01 = oper.Lz
    penalty.smthy01 = 1.0

    penalty.tiamp = 0.0
