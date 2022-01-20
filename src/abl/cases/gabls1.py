"""GABLS1 case"""


def _common(params):
    oper = params.oper
    oper.Lx = 400
    oper.Ly = 400
    oper.Lz = 400

    params.u_geo = 8.0
    params.corio_freq = 1.39e-4

    reynolds_number = 10_000
    params.nek.velocity.viscosity = -reynolds_number

    temperature = params.nek.temperature
    temperature.rho_cp = 1.0
    temperature.conductivity = -reynolds_number


def small(params):
    oper = params.oper

    oper.nx = oper.nz = 4
    oper.ny = 8

    _common(params)
