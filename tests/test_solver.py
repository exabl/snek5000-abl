import pytest

import snek5000


def test_init():
    from abl.solver import Simul

    params = Simul.create_default_params()
    params.output.sub_directory = "test"
    sim = Simul(params)
    # Check params for errors
    params = sim.params
    assert {
        "u_geo",
        "corio_freq",
        "richardson",
        "oper.Lx",
        "oper.Ly",
        "oper.Lz",
    }.issubset(params.nek.general._recorded_user_params.values())
    print(sim.info_solver)


def test_make(sim):
    assert sim.make.exec("mesh", "compile")
    assert sim.make.exec("run", dryrun=True)


def test_load(sim):
    snek5000.load(sim.path_run)
    snek5000.load_for_restart(sim.output.path_session)


@pytest.mark.slow
def test_make_run(sim):
    from snek5000.util import load_for_restart

    # Run in foreground
    assert sim.make.exec("run_fg")

    # test outputs
    print(sim.output.print_stdout.file)
    dt = sim.output.print_stdout.dt
    # number of time steps executed, see conftest.py
    assert dt.size == 9

    from abl.solver import Simul

    # check if simulation can be restarted
    # TODO: try restart with modified params
    params, re_Simul = load_for_restart(sim.path_run, use_checkpoint=True)
    assert Simul is re_Simul
