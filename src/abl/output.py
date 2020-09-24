from snek5000.output.base import Output as OutputBase


class OutputABL(OutputBase):
    name_pkg = "abl"

    @property
    def makefile_usr_sources(self):
        """
        Sources for inclusion to makefile_usr.inc
        Dict[directory]  -> list of source files
        """
        return {
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
                #  ("smagorinsky.f", "SGS", "WMLES"),
                ("dynsmag.f", "DYN", "SGS", "WMLES"),
                ("utils.f", "SGS"),
                ("wmles_init.f", "WMLES", "../toolbox/FRAMELP"),
            ],
            "bc": [("moeng.f", "SGS", "WMLES")],
        }

    @property
    def fortran_inc_flags(self):
        return (f"-I{inc_dir}" for inc_dir in self.makefile_usr_sources)
