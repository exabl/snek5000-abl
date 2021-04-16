"""Channel flow case
====================

.. seealso::

    Lee, Myoungkyu, and Robert D Moser. “Direct Numerical Simulation of
    Turbulent Channel FLow up to Reτ ≈ 5200.” Journal of Fluid Mechanics, 2015,
    21.

"""
from math import nan, pi


def no_penalty(params):
    oper = params.oper

    oper.nx = 14
    oper.ny = 4
    oper.nz = 7

    oper.Lx = round(2 * pi, 4)
    oper.Ly = 2.0
    oper.Lz = round(pi, 4)

    general = params.nek.general

    general.start_from = "ics.f00000"
    general.stop_at = "end_time"
    general.end_time = 1500
    general.num_steps = nan

    general.dt = 5e-3
    general.variable_dt = False

    general.write_control = "runTime"
    general.write_interval = 50

    general.filter_weight = 10
    general.filter_cutoff_ratio = nan
    general.user_params.update({3: 1.0, 4: 0.00})

    reynolds_number = 125_000
    params.nek.velocity.viscosity = -reynolds_number

    params.nek.stat.av_step = 1
    params.nek.stat.io_step = 300

    params.nek.penalty.enabled = False


def with_penalty(params):
    # First populate channel flow parameters
    no_penalty(params)

    oper = params.oper

    penalty = params.nek.penalty
    penalty.enabled = True
    penalty.nregion = 1
    penalty.eposx01 = oper.Lx
    penalty.sposy01 = 0.05 * oper.Ly
    penalty.eposy01 = 0.3 * oper.Ly
    # float(oper.coords_y.split()[1])  # boundary of first element
    penalty.eposz01 = oper.Lz
    penalty.smthy01 = penalty.eposy01 - penalty.sposy01
