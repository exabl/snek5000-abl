import tempfile

from abl.output import OutputABL as Output
from snek5000.solvers import get_solver_package


def test_copy():
    new_dir = tempfile.mkdtemp(__name__)
    output = Output()

    # Inject name_solver and package
    output.name_solver = "abl"
    output.package = get_solver_package(output.name_solver)

    # Fresh copy
    output.copy(new_dir)
    # Redo copy, skip files
    output.copy(new_dir)
    # Redo copy, overwrite files
    output.copy(new_dir, force=True)
