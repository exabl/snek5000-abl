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


def df_richardson_dL(L, z0, z1, Ri_b):
    """Numerical first derivative by Central difference."""
    dL = 1e-4 * L
    f_plus = f_richardson(L + dL, z0, z1, Ri_b)
    f_minus = f_richardson(L - dL, z0, z1, Ri_b)
    return (f_plus - f_minus) / (2 * dL)


def initial_guess_L(z0, Ri_b):
    """This seems like a good guess."""
    return Ri_b * z0 / 10


@np.vectorize
def solve_obukhov_len_secant(z0, z1, Ri_b, L0=None):
    """Solve for Obukhov length using Secant method.

    Parameters
    ----------
    z0: Roughness length
    z1: BC Evaluation height
    Ri_b: Target bulk Richardson number
    L0: Initial guess

    """
    if not L0:
        L0 = initial_guess_L(z0, Ri_b)
    # print(f"{L0=}")
    try:
        # NOTE: No fprime parameter provided
        root, result = newton(
            f_richardson, L0, args=(z0, z1, Ri_b), maxiter=1000, full_output=True
        )
    except RuntimeError:
        print(f"{Ri_b=}, {L0=}")
        raise
    return root, result.iterations


@np.vectorize
def solve_obukhov_len_central(z0, z1, Ri_b, L0=None):
    """Solve for Obukhov length using Newton Raphson + 2nd order Finite difference
    for the derivative

    Parameters
    ----------
    z0: Roughness length
    z1: BC Evaluation height
    Ri_b: Target bulk Richardson number
    L0: Initial guess

    """
    if not L0:
        L0 = initial_guess_L(z0, Ri_b)
    # print(f"{L0=}")
    try:
        root, result = newton(
            f_richardson,
            L0,
            args=(z0, z1, Ri_b),
            maxiter=1000,
            full_output=True,
            fprime=df_richardson_dL,
        )
    except RuntimeError:
        print(f"{Ri_b=}, {L0=}")
        raise
    return root, result.iterations


# # The computation
#
# The iterations fail if:
# - $Ri_b$ is very small, $L \to \infty$, i.e. neutral conditions.
# - $Ri_b > 0.221$ or in other words, $L \to 0$.
# - $z_1 = z_0$
# - $z_1 >> z_0$
# - The error in the initial guess of $L$ is at 100%.

# +
# If we need to start from scratch, uncomment:
#  try:
#      del Ls
#  except NameError:
#      pass

if __name__ == "__main__":
    import matplotlib.pyplot as plt
    import numpy as np

    Ri_small = 1e-4
    Ri_bs = np.concatenate((np.linspace(-4, -Ri_small), np.linspace(Ri_small, 0.221)))

    z0 = 0.1
    z1 = 10 * z0

    try:
        Ls
    except NameError:
        print("First run. No previously computed values for L exist yet")
        L0 = None
    else:
        rel_err = 90
        print(f"Reusing the existing values for L, with a {rel_err}% relative error.")
        L0 = Ls * (1 + rel_err / 100)  # noqa

    # Ls, iters = solve_obukhov_len_secant(z0, z1, Ri_bs, L0)
    Ls, iters = solve_obukhov_len_central(z0, z1, Ri_bs, L0)

    fig, axes = plt.subplots(nrows=2, ncols=2)
    ax00, ax01, ax1, ax2 = axes.ravel()

    ax00.plot(Ri_bs, z1 / Ls)
    ax00.set(ylabel=("$z_1/L$"), xlabel=(r"$Ri_b$"))
    ax01.loglog(-Ri_bs, -z1 / Ls)
    ax01.set(
        ylabel=("$-z_1/L$"), xlabel=(r"$-Ri_b$"), title="Log-log plot as by Businger"
    )

    ax1.plot(Ri_bs, Ls)
    ax1.set(ylabel=("$L$"), xlabel=(r"$Ri_b$"))

    ax2.plot(Ri_bs, iters)
    ax2.set(ylabel="number of iterations", xlabel=(r"$Ri_b$"))

    fig.suptitle(f"{z0=} {z1=}")
    fig.tight_layout()
    plt.show()
# -

# Ensure the sign of L is correct

plt.plot(Ri_bs, np.sign(Ls))
