from functools import partial

import numpy as np


def root2_1m16(xi):
    return (1.0 - 16 * xi) ** 0.5


def root4_1m16(xi):
    return (1.0 - 16 * xi) ** 0.25


def psi_m_stable(xi):
    return -5 * xi


def eval_func_at(z0, z1, L, func):
    r"""Evaluate a integrated stability function :math:`\psi` at a
    elevation :math:`z_1` with roughness :math:`z_0` and
    Obukhov length :math:`L`.
    """
    return np.log(z1 / z0) - func(z1 / L) + func(z0 / L)


PsiM_stable_at = partial(eval_func_at, func=psi_m_stable)
# Because psi_h_stable is identical to psi_m_stable
PsiH_stable_at = PsiM_stable_at


def psi_m_unstable(xi):
    """See ``psi_m_unstable_param`` in the notebook."""
    xi4 = root4_1m16(xi)
    return (
        np.log((1 / 8) * (xi4 + 1) ** 2 * (xi4 ** 2 + 1))
        - 2 * np.arctan(xi4)
        + (1 / 2) * np.pi
    )


def psi_h_unstable(xi):
    """See ``psi_h_unstable_param`` in the notebook."""
    xi2 = root2_1m16(xi)
    return np.log((1 / 4) * (xi2 + 1) ** 2)


PsiM_unstable_at = partial(eval_func_at, func=psi_m_unstable)
PsiH_unstable_at = partial(eval_func_at, func=psi_h_unstable)


@np.vectorize
def richardson(L, z0, z1):
    if L >= 0:
        PsiM_at = PsiM_stable_at
        PsiH_at = PsiH_stable_at
    else:
        PsiM_at = PsiM_unstable_at
        PsiH_at = PsiH_unstable_at

    # For Dirichlet conditions
    return (z1 / L) * (PsiH_at(z0, z1, L) / PsiM_at(z0, z1, L) ** 2)


def f_richardson(L, z0, z1, Ri_b):
    return Ri_b - richardson(L, z0, z1)


def df_richardson_dL(L, z0, z1, Ri_b):
    """Numerical first derivative by Central difference."""
    dL = 1e-4 * L
    f_plus = f_richardson(L + dL, z0, z1, Ri_b)
    f_minus = f_richardson(L - dL, z0, z1, Ri_b)
    return (f_plus - f_minus) / (2 * dL)
