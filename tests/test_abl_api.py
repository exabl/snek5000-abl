import tempfile

from abl import Output


def test_copy():
    new_dir = tempfile.mkdtemp(__name__)
    output = Output()
    # Fresh copy
    output.copy(new_dir)
    # Redo copy, skip files
    output.copy(new_dir)
    # Redo copy, overwrite files
    output.copy(new_dir, force=True)
