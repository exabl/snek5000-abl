import tempfile

from abl.output import OutputABL as Output


def test_copy():
    new_dir = tempfile.mkdtemp(__name__)
    output = Output()

    # Inject name_solver
    output.name_solver = "abl"

    # Fresh copy
    output.copy(new_dir)
    # Redo copy, skip files
    output.copy(new_dir)
    # Redo copy, overwrite files
    output.copy(new_dir, force=True)
