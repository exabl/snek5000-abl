from snek5000 import logger, mpi
from snek5000.info import InfoSolverMake
from snek5000.solvers.kth import SimulKTH

from .output import OutputABL
from .templates import box, makefile_usr, size


class InfoSolverABL(InfoSolverMake):
    """Contain the information on a :class:`eturb.solvers.abl.Simul`
    instance.

    .. todo::

        Move Output info to :class:`InfoSolverNek` and only override it in
        :class:`InfoSolverABL`.

    """

    def _init_root(self):
        super()._init_root()
        self.module_name = "abl.solver"
        self.class_name = "Simul"
        self.short_name = "abl"

        self.classes.Oper.module_name = "abl.operators"
        self.classes.Oper.class_name = "OperatorsABL"

        self.classes.Output.module_name = "abl.output"
        self.classes.Output.class_name = "OutputABL"


class SimulABL(SimulKTH):
    """A solver which compiles and runs using a Snakefile.

    """

    InfoSolver = InfoSolverABL

    @staticmethod
    def _complete_params_with_default(params):
        """Add missing default parameters."""
        params = SimulKTH._complete_params_with_default(params)
        params.nek.velocity._set_attrib("advection", True)

        params.nek._set_child(
            "wmles",
            dict(
                bc_temp_filt=False,
                bc_z_index=1,
                bc_z0=0.1,
                sgs_c0=0.19,
                sgs_delta_max=False,
                sgs_npow=0.5,
            ),
        )
        params.nek.wmles._set_internal_attr("_enabled", True)
        return params

    @classmethod
    def create_default_params(cls):
        """Set default values of parameters as given in reference
        implementation.

        """
        params = super().create_default_params()

        # Synchronize baseline parameters as follows:
        # -----------------------------------------------------------------
        primary_par_file = OutputABL.get_root() / "abl.par"
        if mpi.rank == 0:
            logger.info(f"Reading baseline parameters from {primary_par_file}")

        params.nek._read_par(primary_par_file)

        return params

    def __init__(self, params):
        super().__init__(params)
        self.output.write_box(box)
        self.output.write_size(size)
        self.output.write_makefile_usr(makefile_usr)

    def sanity_check(self):
        """Check params for errors"""
        params = self.params
        assert params.oper.Lx == params.nek.general.user_params[5]
        assert params.oper.Ly == params.nek.general.user_params[6]
        assert params.oper.Lz == params.nek.general.user_params[7]


Simul = SimulABL
