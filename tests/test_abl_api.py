import shutil
import tempfile

from abl import Case


def test_copy():
    new_dir = tempfile.mkdtemp(__name__)
    case = Case()
    # Fresh copy
    case.copy(new_dir)
    # Redo copy, skip files
    case.copy(new_dir)
    # Redo copy, overwrite files
    case.copy(new_dir, force=True)
