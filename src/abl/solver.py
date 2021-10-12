from snek5000.info import InfoSolverMake
from snek5000.solvers.kth import SimulKTH


class InfoSolverABL(InfoSolverMake):
    """Contain the information on a :class:`abl.solver.SimulABL`
    instance.

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

        self.classes._set_child(
            "Postproc",
            attribs={"module_name": "abl.postproc", "class_name": "PostprocABL"},
        )


class SimulABL(SimulKTH):
    """A solver which compiles and runs using a Snakefile."""

    InfoSolver = InfoSolverABL

    @staticmethod
    def _complete_params_with_default(params):
        """Add missing default parameters."""
        params = SimulKTH._complete_params_with_default(params)
        params.nek.velocity._set_attribs({"advection": True, "density": 1.0})
        params.nek.temperature._set_internal_attr("_enabled", True)

        params.nek._set_child(
            "wmles",
            dict(
                bc_temp_filt=False,
                bc_z_index=1,
                bc_z0=0.1,
                sgs_bc=False,
                sgs_c0=0.19,
                sgs_delta_max=False,
                sgs_npow=0.5,
            ),
        )
        params.nek._set_child(
            "penalty",
            dict(
                enabled=False,  # Enable penalty term
                nregion=0,  # Number of penalty regions
                tiamp=0.0,  # Time independent amplitude
                #  tdamp=0.e+00,  # Time dependent amplitude
                sposx01=0.0,  # Starting point X
                sposy01=0.0,  # Starting point Y
                sposz01=0.0,  # Starting point Z
                eposx01=0.0,  # Ending point X
                eposy01=0.0,  # Ending point Y
                eposz01=0.0,  # Ending point Z
                smthx01=0.0,  # Smoothing length X
                smthy01=0.0,  # Smoothing length Y
                smthz01=0.0,  # Smoothing length Z
                #  rota01=0.e+00,  # Rotation angle
                #  fdt01=0.e+00,  # Time step for penalty
                sposx02=0.0,  # Starting point X
                sposy02=0.0,  # Starting point Y
                sposz02=0.0,  # Starting point Z
                eposx02=0.0,  # Ending point X
                eposy02=0.0,  # Ending point Y
                eposz02=0.0,  # Ending point Z
                smthx02=0.0,  # Smoothing length X
                smthy02=0.0,  # Smoothing length Y
                smthz02=0.0,  # Smoothing length Z
            ),
        )
        params.nek._set_child(
            "spongebx",
            dict(
                strength=0.0,  # sponge strength
                width_lx=0.0,  # sponge left section width; dimension X
                width_ly=0.0,  # sponge left section width; dimension Y
                width_lz=0.0,  # sponge left section width; dimension Z
                width_rx=0.0,  # sponge right section width; dimension X
                width_ry=0.0,  # sponge right section width; dimension Y
                width_rz=0.0,  # sponge right section width; dimension Z
                drop_lx=0.0,  # sponge left drop/rise section width; dimension X
                drop_ly=0.0,  # sponge left drop/rise section width; dimension Y
                drop_lz=0.0,  # sponge left drop/rise section width; dimension Z
                drop_rx=0.0,  # sponge right drop/rise section width; dimension X
                drop_ry=0.0,  # sponge right drop/rise section width; dimension Y
                drop_rz=0.0,  # sponge right drop/rise section width; dimension Z
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
        #  primary_par_file = OutputABL.get_root() / "abl.par"
        #  if mpi.rank == 0:
        #      logger.info(f"Reading baseline parameters from {primary_par_file}")
        #
        #  params.nek._read_par(primary_par_file)

        return params

    def __init__(self, params):
        super().__init__(params)

        self.postproc.post_init(self)


Simul = SimulABL
