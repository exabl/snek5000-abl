import shutil
import tempfile

import abl


def test_copy():
    new_dir = tempfile.mkdtemp(__name__)
    # Fresh copy
    abl.copy(new_dir)
    # Redo copy, skip files
    abl.copy(new_dir)
    # Redo copy, overwrite files
    abl.copy(new_dir, force=True)
