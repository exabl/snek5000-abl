"""Postprocessing output files


**Contents**

.. autosummary::
   :toctree:

   spatial_means
   stats

"""
from inflection import underscore


class PostprocABL:
    @staticmethod
    def _complete_info_solver(info_solver):
        """Complete the ParamContainer info_solver."""
        classes = info_solver.classes.Postproc._set_child("classes")

        classes._set_child(
            "SpatialMeans",
            attribs={
                "module_name": "abl.postproc.spatial_means",
                "class_name": "SpatialMeansABL",
            },
        )

    def __init__(self, sim):
        self.sim = sim

    def post_init(self, sim):
        dict_classes = self.sim.info_solver.classes.Postproc.import_classes()
        for cls_name, Class in dict_classes.items():
            # only initialize if Class is not the Simul class
            if not isinstance(self, Class):
                setattr(self, underscore(cls_name), Class(sim))

    def load(self):
        """Load results for postprocessing."""
        dict_classes = self.sim.info_solver.classes.Postproc.import_classes()

        for cls_name in dict_classes:
            cls = getattr(self, underscore(cls_name))
            cls.load()
