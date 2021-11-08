"""Non-rotating neutral ABL case
================================

.. seealso::

    Maronga, Björn, Christoph Knigge, and Siegfried Raasch. “An Improved
    Surface Boundary Condition for Large-Eddy Simulations Based on
    Monin–Obukhov Similarity Theory: Evaluation and Consequences for Grid
    Convergence in Neutral and Stable Conditions.” Boundary-Layer Meteorology,
    October 29, 2019. https://doi.org/10.1007/s10546-019-00485-w.

"""


def _common(params):
    oper = params.oper
    oper.Lx = 640
    oper.Ly = 1500
    oper.Lz = 640

    params.u_geo = 5.0
    params.corio_freq = 0.00014


def small(params):
    oper = params.oper

    oper.nx = oper.nz = 4
    oper.ny = 20

    z_wall = oper.origin_y
    oper.coords_y = (
        f"{z_wall} 34.6 72.8 115. 161. 211. 266. 326. 390. 459. 534. 613. 697. "
        "786. 879. 976. 1076. 1180. 1285. 1392. 1500."
    )
    _common(params)


def large(params):
    oper = params.oper

    oper.nx = oper.nz = 4
    oper.ny = 32

    z_wall = oper.origin_y
    oper.coords_y = (
        f"{z_wall} 5.4 11.6 18.7 26.8 36 46.5 58.5 72 87.5 105 125 147 173 201 "
        "233 269 310 354 404 458 518 583 654 731 812 900 991 1088 1187 "
        "1290 1394 1500"
    )
    _common(params)
