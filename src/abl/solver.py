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


Simul = SimulABL