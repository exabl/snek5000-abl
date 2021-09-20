"""Half-channel flow case
==========================
Half channel version of the Lee and Moser channel flow case.

.. seealso::

    Lee, Myoungkyu, and Robert D Moser. “Direct Numerical Simulation of
    Turbulent Channel FLow up to Reτ ≈ 5200.” Journal of Fluid Mechanics, 2015,
    21.

"""
from math import pi


def _common(params):
    oper = params.oper

    oper.nx = 16
    oper.ny = 8
    oper.nz = 16

    oper.Lx = round(2 * pi, 4)
    oper.Ly = 1.0
    oper.Lz = round(pi, 4)
