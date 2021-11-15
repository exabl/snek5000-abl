import matplotlib.pyplot as plt
import numpy as np

from snek5000.output.phys_fields import PhysFields
from ..readers.pymech_avg import ReaderPymechStatsAvg


class PhysFieldsABL(PhysFields):
    @staticmethod
    def _complete_info_solver(info_solver, classes=None):
        PhysFields._complete_info_solver(info_solver, classes=(ReaderPymechStatsAvg,))

    @property
    def u_mean(self):
        data = self.data
        return (data.s01 ** 2 + data.s02 ** 2) ** 0.5

    @property
    def u_star(self):
        return float(self.tau.isel(y=0) ** 0.5)

    @property
    def tau(self):
        data = self.data
        return -data.s11 + (data.s47 ** 2 + data.s50 ** 2) ** 0.5

    def plot_turb_mom_flux(self, marker="x"):
        fix, ax = plt.subplots()
        data = self.data
        ax.plot("s11", "y", "", marker=marker, label="u'w'", data=data)
        ax.plot("s10", "y", "", marker=marker, label="v'w'", data=data)
        ax.set(ylabel="$z$")
        ax.legend()
        return ax

    def plot_mean_vel(self, marker="x"):
        fix, ax = plt.subplots()
        data = self.data
        ax.plot("s01", "y", "", marker=marker, label="U", data=data)
        ax.plot("s02", "y", "", marker=marker, label="V", data=data)
        ax.set(ylabel="$z$")
        ax.legend()
        return ax

    def plot_stress(self):
        tau = self.tau
        fix, ax = plt.subplots()
        ax.plot(tau, self.data.y)
        ax.set(xlabel=r"$\tau$", ylabel="$z$")
        return ax

    def plot_log_law(self, marker="x", scaled=True, z0_eff=None, start_idx=0):
        """Plot log law vs MOST theory.

        Parameters
        ----------
        marker : str
            Marker over U:computed
        scaled : bool
            To scale in plus-units or not
        z0_eff : float
            Make a plot with estimated effective z0
        start_idx : int
            Start index of all data, useful to omit by setting ``start_idx=1``
            if the data begins at z=0.  Only needed to ensure the plot renders
            well in a semi-log plot.
        """
        z = self.data.y

        z0 = self.output.sim.params.nek.wmles.bc_z0
        u_star = self.u_star
        kappa = 0.41
        idx = slice(start_idx, None)

        if scaled:
            Re = abs(self.output.sim.params.nek.velocity.viscosity)
            nu = 1 / Re
            u_scale = u_star
            z_scale = nu / float(u_star)
            xlabel = "$u_+$"
            ylabel = "$z_+$"
        else:
            u_scale = z_scale = 1.0
            xlabel = "$u$"
            ylabel = "$z$"

        U = self.u_mean
        U_most = u_star / kappa * np.log(z / z0)

        fig, ax = plt.subplots()
        ax.plot(
            (U / u_scale)[idx],
            z[idx] / z_scale,
            marker="x",
            label=r"$U$: computed",
        )
        ax.plot(
            (U_most / u_scale)[idx],
            z[idx] / z_scale,
            linestyle="--",
            label=r"$U$: MOST",
        )

        if z0_eff:
            U_eff = u_star / kappa * np.log(z / z0_eff)
            ax.plot(
                (U_eff / u_scale)[idx],
                z[idx] / z_scale,
                linestyle=":",
                label=r"$U$: effective",
            )
            title = f", $z_{{0,eff}}$={z0_eff:0.1e}"
        else:
            title = ""

        ax.set(
            ylim=(z[idx].min(), z.max()),
            yscale="log",
            ylabel=ylabel,
            xlabel=xlabel,
            title=f"$u^*$ = {float(u_star):.2f}, $z_0$ = {z0:.1e}{title}",
        )
        ax.legend()
        return ax

    def plot_ekman_spiral(self, marker="x", angle=None):
        """Plot hodograph to reveal the Ekman spiral.

        Parameters
        ----------
        marker :
            marker
        angle : float
            Angle in degrees
        """
        fig, ax = plt.subplots()
        U = self.data.s01
        V = self.data.s03

        ax.plot(U, V, c="k")
        scatter = ax.scatter(U, V, c=self.data.y, marker=marker)
        fig.colorbar(scatter, label="z")
        ax.set(xlabel="U", ylabel="V", title="Ekman spiral")

        if angle:
            u_angle = np.linspace(0, 0.2 * U.max(), 20)
            v_angle = np.tan(np.radians(angle)) * u_angle
            ax.plot(u_angle, v_angle, linestyle="--", color="green")

        return ax
