from contextlib import contextmanager
from pathlib import Path
from tarfile import TarFile

import zstandard as zstd
from pymech.dataset import open_mfdataset

from .solver import Simul


@contextmanager
def open_tar_zst(path_tar_zst, mode="rb"):
    """Decompress and open a .tar.zst file"""
    with open(path_tar_zst, mode) as fh:
        if mode == "rb":
            dctx = zstd.ZstdDecompressor()
            with dctx.stream_reader(fh) as stream:
                yield TarFile(fileobj=stream)
        elif mode == "r+b":
            #  FIXME: Writing files into
            cctx = zstd.ZstdCompressor()
            with cctx.stream_writer(fh) as stream:
                yield TarFile(fileobj=stream)
        else:
            raise NotImplementedError(f"Unsupported file mode: {mode}")


def load_simul(path_dir, prefix="abl", extract_tarballs=True, **kwargs):
    """Load simulation data and parameters.

    Parameters
    ----------

    path_dir: str
        Path to simulation

    prefix: str
        Field file prefix

    extract_tarballs: bool
        Extract simulation tarballs

    kwargs: dict
        Keyword arguments passed to ``pymech.open_mfdataset``

    """
    path_dir = Path(path_dir)
    params = Simul.load_params_from_file(path_dir / "params_simul.xml")
    ds = open_mfdataset(path_dir.glob(f"{prefix}0.f*"), **kwargs)

    if extract_tarballs:
        raise NotImplementedError("Need to use open_tar_zst")

    return params, ds
