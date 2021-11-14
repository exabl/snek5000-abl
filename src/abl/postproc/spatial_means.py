from functools import partial
from pathlib import Path

import pandas as pd


class SpatialMeansABL:
    def __init__(self, sim):
        self.file = Path(sim.path_run / "spatial_means.txt")

    def load(self):
        df = pd.read_csv(self.file, sep=r"\s+", index_col="it")
        df["hours"] = df.t / 3600
        self.df = df

        self.plot = partial(self.df.plot, x="t")
        return df
