import os

import numpy as np
import pymech as pm
import pytest
from numpy.testing import assert_allclose


@pytest.mark.skipif(not os.getenv("SNEK_DEBUG"), reason="Requires debug penalty files")
@pytest.mark.parametrize("nb_regions", [1, 2])
def test_penalty_regions(nb_regions):
    from abl.cases.lee_moser import small_with_penalty as case
    from abl.solver import Simul

    # from abl.cases.chat_peet import small as case

    params = Simul.create_default_params()
    case(params)

    params.nek.problemtype.stress_formulation = True
    # params.output.boundary_cond = "channel"
    # params.oper.boundary = ["P", "P", "sh", "sh", "P", "P"]
    params.output.boundary_cond = "moeng"
    params.oper.boundary = ["P", "P", "sh", "W", "P", "P"]

    params.nek.penalty.nregion = nb_regions
    params.nek.penalty.tiamp = -1e-6

    general = params.nek.general
    general.stop_at = "num_steps"
    general.num_steps = 9

    sim = Simul(params)
    assert sim.make.exec(["run_fg"]), "Debug run with penalties failed to complete"
    check_mesh_coords(sim)
    check_penalty_debug_output(sim, tuple(range(1, nb_regions + 1)))


def check_mesh_coords(sim):
    ds = pm.open_dataset(next(sim.path_run.glob("abl*.f*1")))
    ds1 = ds.mean(["x", "z"])

    # Check if y coordinate grows monotonically
    assert (ds1.ymesh[1:].data >= ds1.ymesh[:-1].data).all()


def check_penalty_debug_output(sim, regions):
    ds = pm.open_dataset(next(sim.path_run.glob("penabl*.f*1")))
    ds1 = ds.mean(["x", "z"])

    z0 = sim.params.nek.wmles.bc_z0

    y_coord = ds1.y.values
    threshold = 1e-14
    y_nonzero = y_coord.copy()
    y_nonzero[np.greater(threshold, y_coord)] = threshold

    abl_pen_k = y_coord * np.log(y_nonzero / z0)
    assert_allclose(ds1.ux, abl_pen_k, err_msg="Penalty K term is wrong")

    def mask_indices(region_idx):
        pen = sim.params.nek.penalty
        idx = f"{region_idx:02d}"

        y_smth = getattr(pen, f"smthy{idx}")
        y_start = getattr(pen, f"sposy{idx}")
        y_end = getattr(pen, f"eposy{idx}")

        y_len = (y_end - y_start) * 0.5
        y_cen = (y_end + y_start) * 0.5

        yr = (ds1.y - y_cen) / y_len
        mask = ~(abs(yr / y_smth) > 1.0)
        # (y_start <= ds1.y) & (ds1.y <= y_end)
        return mask

    if 1 in regions:
        # Bitwise inversion / complement of the mask
        complement = ds1.uy[~mask_indices(1)]
        assert_allclose(
            complement,
            np.zeros_like(complement),
            err_msg="Complement mask for region 1 is wrong",
        )

        mask = ds1.uy[mask_indices(1)]
        assert_allclose(mask, np.ones_like(mask), err_msg="Mask for region 1 is wrong")

    if 2 in regions:
        complement = ds1.uz[~mask_indices(2)]
        assert_allclose(
            complement,
            np.zeros_like(complement),
            err_msg="Complement mask for region 2 is wrong",
        )

        mask = ds1.uz[mask_indices(2)]
        assert_allclose(mask, np.ones_like(mask), err_msg="Mask for region 2 is wrong")
