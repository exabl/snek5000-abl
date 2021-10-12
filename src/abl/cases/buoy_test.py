"""Buoyancy test case

"""
from math import nan, pi


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

    general = params.nek.general
    general.filter_cutoff_ratio = nan
    general.filter_weight = 12.0
    general.user_params.update({3: 1.0, 4: 0.0014})

    reynolds_number = 10_000
    params.nek.velocity.viscosity = -reynolds_number

    temperature = params.nek.temperature
    temperature.rho_cp = 1.0
    temperature.conductivity = -reynolds_number

    # Not relevant while using no-slip BC + mixing length SGS.
    wmles = params.nek.wmles
    wmles.bc_z_index = 12
    wmles.sgs_c0 = 0.15


def variable_properties(params):
    params.nek.problemtype.variable_properties = True
    _common(params)


def no_variable_properties(params):
    params.nek.problemtype.variable_properties = False
    _common(params)


def no_vp_sponge(params):
    no_variable_properties(params)

    oper = params.oper
    oper.nx = 16
    oper.ny = 4
    oper.nz = 4

    oper.Lx = 15.0
    oper.Ly = 1.0
    oper.Lz = 1.5
    general = params.nek.general

    spongebx = params.nek.spongebx

    sponge_height = 0.4
    spongebx.width_ry = sponge_height
    spongebx.drop_ry = sponge_height * 0.5
