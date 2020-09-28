from snek5000.output.base import Output as OutputBase


class OutputABL(OutputBase):
    name_pkg = "abl"

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
            "bc": [],
        }

        if not self.sim:
            # Hack to load params from current file
            from abl.solver import Simul

            params = Simul.load_params_from_file(path_xml="params.xml")
        else:
            params = self.sim.params

        if params.output.sgs_model == "constant":
            sources["sgs"].append(("smagorinsky.f", "SGS", "WMLES"))
        elif params.output.sgs_model == "dynamic":
            sources["sgs"].append(("dyn_smag.f", "DYN", "SGS", "WMLES"))
        else:
            raise NotImplementedError(f"SGS model {params.output.sgs_model}")

        if params.output.boundary_cond == "moeng":
            sources["bc"].append(("moeng.f", "../sgs/SGS", "../sgs/WMLES"))
        elif params.output.boundary_cond == "noslip":
            sources["bc"].append(("noslip.f",))
        else:
            raise NotImplementedError(
                f"Boundary condition {params.output.boundary_cond}"
            )

        return sources

    @property
    def fortran_inc_flags(self):
        return (f"-I{inc_dir}" for inc_dir in self.makefile_usr_sources)

    @staticmethod
    def _complete_params_with_default(params, info_solver):
        OutputBase._complete_params_with_default(params, info_solver)
        params.output._set_attribs({"sgs_model": "constant", "boundary_cond": "moeng"})
