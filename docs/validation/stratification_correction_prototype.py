from functools import partial

import numpy as np
from scipy.optimize import newton


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


@np.vectorize
def solve_obukhov_len_secant(z0, z1, Ri_b, L0=None):
    """Solve for Obukhov length using Newton Raphson + Secant method
    for the derivative

    Parameters
    ----------
    z0: Roughness length
    z1: BC Evaluation height
    Ri_b: Target bulk Richardson number
    L0: Initial guess

    """
    if not L0:
        L0 = Ri_b * z0 / 10
    # print(f"{L0=}")
    try:
        result = newton(
            f_richardson, L0, args=(z0, z1, Ri_b), maxiter=1000, full_output=True
        )
    except RuntimeError:
        print(f"{Ri_b=}, {L0=}")
        raise
    return result[0]


if __name__ == "__main__":
    import matplotlib.pyplot as plt
    import numpy as np

    Ri_small = 1e-2
    Ri_bs = np.concatenate((np.linspace(-5, -Ri_small), np.linspace(Ri_small, 0.2)))

    z0 = 0.0001
    z1 = 10 * z0
    Ls = solve_obukhov_len_secant(z0, z1, Ri_bs)
    plt.plot(Ri_bs, z1 / Ls)
    plt.ylabel("$z_1/L$")
    plt.xlabel(r"$Ri_b$")
    plt.show()

    plt.plot(Ri_bs, Ls)
    plt.ylabel("$L$")
    plt.xlabel(r"$Ri_b$")
