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

        params.nek.problemtype.variable_properties = True

        params.nek.velocity._set_attribs(
            {
                "advection": True,
                "density": 1.0,
            }
        )
        params.nek.pressure.residual_proj = True

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
        params.nek.wmles._set_internal_attr("_enabled", True)

        params.nek._set_child(
            "flow_phys",
            dict(
                corio_on=True,
                corio_freq=1.4e-4,
                u_geo=5.0,
            ),
        )
        params.nek.flow_phys._set_internal_attr("_enabled", True)
        return params

    @classmethod
    def create_default_params(cls):
        """Set default values of parameters as given in reference
        implementation.

        """
        params = super().create_default_params()

        return params

    def __init__(self, params):
        super().__init__(params)

        self.postproc.post_init(self)


Simul = SimulABL
