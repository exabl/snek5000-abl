"""Open channel non-rotating case
=================================

.. seealso::

    Chatterjee, Tanmoy, and Yulia T. Peet. “Effect of Artificial Length Scales
    in Large Eddy Simulation of a Neutral Atmospheric Boundary Layer Flow: A
    Simple Solution to Log-Layer Mismatch.” Physics of Fluids 29, no. 7 (July
    2017): 075105. https://doi.org/10.1063/1.4994603.

"""
from math import pi


def _common(params):
    general = params.nek.general
    general.user_params = {
        3: 1.0,  # Bulk mean velocity
        4: 0.0,  # Coriolis freq turned off?
    }

    oper = params.oper
    oper.Lx = round(2 * pi, 4)
    oper.Ly = 1.0
    oper.Lz = round(pi, 4)


def small(params):
    oper = params.oper
    oper.nx = 6
    oper.ny = 20
    oper.nz = 6
    _common(params)


def medium(params):
    oper = params.oper
    oper.nx = 12
    oper.ny = 24
    oper.nz = 12
    _common(params)


def large(params):
    oper = params.oper
    oper.nx = 24
    oper.ny = 48
    oper.nz = 24
    _common(params)


def small_stretch(params):
    # Similar to M 12 - scaled by 1500
    oper = params.oper
    oper.nx = 3
    oper.ny = 20
    oper.nz = 3

    z_wall = oper.origin_y
    oper.coords_y = (
        f"{z_wall} 0.0231 0.0485 0.0767 0.1073 0.1407 0.1773 0.2173 0.2600 "
        "0.3060 0.3560 0.4087 0.4647 0.5240 0.5860 0.6507 0.7173 0.7867 "
        "0.8567 0.9280 1.000"
    )
    _common(params)


def medium_stretch(params):
    small_stretch(params)
    oper = params.oper
    oper.nx = 8
    oper.nz = 8


def large_stretch(params):
    oper = params.oper
    # Similar to M 11 - scaled by 1500
    oper.nx = 4
    oper.ny = 32
    oper.nz = 4
    z_wall = oper.origin_y
    oper.coords_y = (
        f"{z_wall} 0.0036 0.0077 0.0125 0.0179 0.0240 0.0310 0.0390 0.0480 "
        "0.0583 0.0700 0.0833 0.0980 0.1153 0.1340 0.1553 0.1793 0.2067 "
        "0.2360 0.2693 0.3053 0.3453 0.3887 0.4360 0.4873 0.5413 0.6000 "
        "0.6607 0.7253 0.7913 0.8600 0.9293 1.000"
    )
    _common(params)
