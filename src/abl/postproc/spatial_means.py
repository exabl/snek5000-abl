from pathlib import Path

import pandas as pd


class SpatialMeansABL:
    def __init__(self, sim):
        path_run = sim.path_run

        df = pd.read_csv(
            Path(path_run) / "spatial_means.txt", sep=r"\s+", index_col="it"
        )
        df["hours"] = df.t / 3600
        self.df = df

        self.plot = self.df.plot
