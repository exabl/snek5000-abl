"""Buoyancy test case

"""
from math import pi


def _common(params):
    oper = params.oper

    oper.nx = 8
    oper.ny = 4
    oper.nz = 8

    oper.Lx = round(2 * pi, 4)
    oper.Ly = 1.0
    oper.Lz = round(pi, 4)

    z_wall = oper.origin_y

    oper.coords_y = f"{z_wall} 0.1 0.3 0.6 1.0"
