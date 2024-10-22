import numpy as np

# Fortran
# Note: execute `make lib` to generate the Fortran library
import strat_correct_f as ftn
from scipy.optimize import newton

# Python
# from strat_correct import f_richardson, df_richardson_dL


f_richardson = np.vectorize(ftn.f_richardson)
df_richardson_dL = np.vectorize(ftn.df_richardson_dl)

TOLERANCE = 1e-8


def initial_guess_L(z0, Ri_b):
    """This seems like a good guess."""
    return Ri_b * z0 / 10


@np.vectorize
def solve_obukhov_len_secant(z0, z1, Ri_b, L0):
    """Solve for Obukhov length using Secant method.

    Parameters
    ----------
    z0: Roughness length
    z1: BC Evaluation height
    Ri_b: Target bulk Richardson number
    L0: Initial guess

    """
    try:
        # NOTE: No fprime parameter provided
        root, result = newton(
            f_richardson,
            L0,
            args=(z0, z1, Ri_b),
            tol=TOLERANCE,
            maxiter=1000,
            full_output=True,
        )
    except RuntimeError:
        print(f"{Ri_b=}, {L0=}")
        raise
    return root, result.iterations


@np.vectorize
def solve_obukhov_len_central(z0, z1, Ri_b, L0):
    """Solve for Obukhov length using Newton Raphson + 2nd order Finite difference
    for the derivative

    Parameters
    ----------
    z0: Roughness length
    z1: BC Evaluation height
    Ri_b: Target bulk Richardson number
    L0: Initial guess

    """
    try:
        root, result = newton(
            f_richardson,
            L0,
            args=(z0, z1, Ri_b),
            tol=TOLERANCE,
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

    Ri_small = 0.01
    Ri_bs = np.concatenate(
        (
            np.linspace(-5, -Ri_small),
            np.linspace(Ri_small, 0.22),
        )
    )

    z0 = 0.1
    z1 = 10 * z0

    try:
        Ls
    except NameError:
        print("First run. No previously computed values for L exist yet")
        L0 = initial_guess_L(z0, Ri_bs)
    else:
        rel_err = 90
        print(f"Reusing the existing values for L, with a {rel_err}% relative error.")
        L0 = Ls * (1 + rel_err / 100)  # noqa

    # Ls, iters = solve_obukhov_len_secant(z0, z1, Ri_bs, L0)
    Ls, iters = solve_obukhov_len_central(z0, z1, Ri_bs, L0)

    fig, axes = plt.subplots(nrows=3, ncols=2, figsize=(8, 12))
    ax00, ax01, ax1, ax2, ax30, ax31 = axes.ravel()

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

    if L0 is not None:
        ax30.plot(Ri_bs, f_richardson(L0, z0, z1, Ri_bs))
        ax30.axhline(0, color="black")
        ax30.set(ylabel=("$f(L_0)$"), xlabel=(r"$Ri_b$"))

        ax31.plot(Ri_bs, df_richardson_dL(L0, z0, z1, Ri_bs))
        ax31.axhline(0, color="black")
        ax31.set(ylabel=(r"$\partial f(L_0) / \partial L$"), xlabel=(r"$Ri_b$"))

    for ax in ax30, ax31:
        ax.set_title("Initial guess")

    fig.suptitle(f"{z0=} {z1=}")
    fig.tight_layout()
    plt.show()
    # -

    # Ensure the sign of L is correct

    np.all(np.sign(Ri_bs) == np.sign(Ls))

    # +
    L_thresh = 5

    RI_B, L = np.meshgrid(Ri_bs, np.linspace(-L_thresh, L_thresh))
    F = f_richardson(L, z0, z1, RI_B)
    DF_DL = df_richardson_dL(L, z0, z1, RI_B)

    fig, axes = plt.subplots(ncols=3, sharey=True, figsize=(15, 4))
    ax0, ax1, ax2 = axes.ravel()
    fig.colorbar(ax0.contourf(RI_B, L, F), ax=ax0)
    fig.colorbar(ax1.contourf(RI_B, L, DF_DL, levels=20, cmap="inferno"), ax=ax1)
    fig.colorbar(ax2.contourf(RI_B, L, np.log(abs(DF_DL)), cmap="inferno"), ax=ax2)

    ax0.plot(Ri_bs, L0, color="red", label="Initial $L_0$")
    ax0.plot(Ri_bs, Ls, color="white", label="Final $L$")
    ax0.set_ylim(-L_thresh, L_thresh)
    ax0.legend()

    for ax, title in zip(
        axes, ("$f$", r"$\partial f/ \partial L$", r"$\ln(|\partial f / \partial L|)$")
    ):
        ax.set(ylabel="L", xlabel="$Ri_b$", title=title)
    # -
