from snek5000.output.readers.pymech_ import ReaderPymechStats


class ReaderPymechStatsAvg(ReaderPymechStats):
    """Horizontally and temporally average statistics"""

    tag = "pymech_stats_avg"

    def load(self, prefix="sts", index="all", t_stat=None, **kwargs):
        ds = super().load(prefix, index, **kwargs)

        avg_dims = ("x", "time")
        self.data = ds.sel(z=0, time=slice(t_stat, None)).mean(avg_dims)
        return self.data
