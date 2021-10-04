import itertools
import os
from collections import namedtuple

from abl.templates import box, makefile_usr, size
from snek5000 import mpi
from snek5000.output.base import Output as OutputBase

SGS = namedtuple("SGS", ["name", "sources"])
# Specific SGS models
constant = SGS("constant", ("smagorinsky.f", "SGS", "WMLES"))
dynamic = SGS("dynamic", ("dyn_smag.f", "DYN", "SGS", "WMLES"))
shear_imp = SGS("shear_imp", ("shear_imp_smag.f", "SGS", "WMLES"))
vreman = SGS("vreman", ("vreman.f", "SGS", "WMLES"))
mixing_len = SGS("mixing_len", ("mixing_len.f", "SGS", "WMLES"))
channel_mixing_len = SGS("channel_mixing_len", ("channel_mixing_len.f", "SGS", "WMLES"))

BC = namedtuple("BC", ["name", "sources"])
# Specific boundary conditions
channel = BC("channel", ("channel.f", "../sgs/SGS", "../sgs/WMLES"))
moeng = BC("moeng", ("moeng.f", "../sgs/SGS", "../sgs/WMLES"))
noslip = BC("noslip", ("noslip.f", "../sgs/SGS", "../sgs/WMLES"))


avail_sgs_models = {
    model.name: model for model in locals().values() if isinstance(model, SGS)
}
avail_boundary_conds = {
    model.name: model for model in locals().values() if isinstance(model, BC)
}
avail_temp_boundary_conds = {"isotherm", "flux"}


class OutputABL(OutputBase):
    name_pkg = "abl"

    @staticmethod
    def _complete_params_with_default(params, info_solver):
        OutputBase._complete_params_with_default(params, info_solver)
        params.output._set_attribs(
            {
                "sgs_model": "constant",
                "boundary_cond": "moeng",
                "buoyancy_bottom": "isotherm",
                "buoyancy_top": "isotherm",
            }
        )

    @property
    def makefile_usr_sources(self):
        """
        Sources for inclusion to makefile_usr.inc
        Dict[directory]  -> list of source files
        """
        sources = {
            "toolbox": [
                ("frame.f", "FRAMELP"),
                ("mntrlog_block.f", "MNTRLOGD"),
                ("mntrlog.f", "MNTRLOGD"),
                ("mntrtmr_block.f", "MNTRLOGD", "MNTRTMRD"),
                ("mntrtmr.f", "MNTRLOGD", "MNTRTMRD", "FRAMELP"),
                ("rprm_block.f", "RPRMD"),
                ("rprm.f", "RPRMD", "FRAMELP"),
                ("io_tools_block.f", "IOTOOLD"),
                ("io_tools.f", "IOTOOLD"),
                ("chkpoint.f", "CHKPOINTD"),
                ("chkpt_mstp.f", "CHKPTMSTPD", "CHKPOINTD"),
                ("map2D.f", "MAP2D", "FRAMELP"),
                ("stat.f", "STATD", "MAP2D", "FRAMELP", "../sgs/SGS"),
                ("stat_IO.f", "STATD", "MAP2D", "FRAMELP"),
                ("math_tools.f",),
            ],
            "sgs": [
                ("utils.f", "SGS"),
                ("wmles_init.f", "WMLES", "../toolbox/FRAMELP"),
            ],
            "forcing": [
                (
                    "penalty_mini.f",
                    "PENALTY",
                    "../sgs/SGS",
                    "../sgs/WMLES",
                ),
                ("penalty_utils.f",),
                (
                    "penalty_par.f",
                    "PENALTY",
                    "../toolbox/FRAMELP",
                ),
            ],
            "sponge_box": [("spongebx.f", "SPONGEBXD")],
            "bc": [],
        }

        if not self.sim and not self.params:
            # Hack to load params from params.xml in current directory
            from abl.solver import Simul

            params = Simul.load_params_from_file(path_xml="params_simul.xml").output
        else:
            params = self.params

        if params.sgs_model not in avail_sgs_models:
            raise NotImplementedError(
                f"SGS model {params.sgs_model}. " f"Must be in {avail_sgs_models}."
            )

        if params.boundary_cond not in avail_boundary_conds:
            raise NotImplementedError(
                f"Boundary condition {params.boundary_cond}. "
                f"Must be in {avail_boundary_conds}."
            )

        sgs = avail_sgs_models[params.sgs_model]
        sources["sgs"].append(sgs.sources)
        if sgs.name in (
            "constant",
            "shear_imp",
            "vreman",
            "mixing_len",
            "channel_mixing_len",
        ):
            sources["toolbox"].append(("stat_extras_dummy.f",))

        bc = avail_boundary_conds[params.boundary_cond]
        sources["bc"].append(bc.sources)
        return sources

    def write_makefile_usr(self, template, fp=None, **template_vars):
        # Prepare dictionary for overriding custom fortran flags
        flags_var = {
            sources[0]: "$(CUSTOM_FFLAGS)"
            for sources in itertools.chain.from_iterable(
                self.makefile_usr_sources.values()
            )
        }

        if os.getenv("SNEK_DEBUG"):
            custom_fortran_flags = (
                "$(subst -w,,$(FL2)) -fcheck=all -Wall -Wextra -Waliasing "
                "-Wsurprising -Wcharacter-truncation -Wno-unused-parameter"
            )

            # NOTE: special overrides
            flags_var["penalty_utils.f"] = custom_fortran_flags.replace(
                "-fcheck=all", ""
            )
        else:
            custom_fortran_flags = "$(FL2)"

        template_vars["flags_var"] = flags_var
        template_vars["custom_fortran_flags"] = custom_fortran_flags
        super().write_makefile_usr(template, fp, **template_vars)

    def post_init(self):
        params = self.sim.params
        params.nek.general.user_params[5] = params.oper.Lx
        params.nek.general.user_params[6] = params.oper.Ly
        params.nek.general.user_params[7] = params.oper.Lz

        super().post_init()

        # Write additional source files to compile the simulation
        if mpi.rank == 0 and self._has_to_save and self.sim.params.NEW_DIR_RESULTS:
            self.write_box(box)
            self.write_size(size)
            self.write_makefile_usr(makefile_usr)
