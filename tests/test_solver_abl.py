import pytest

from eturb.util import prepare_for_restart


def test_init(sim):
    print(sim.info_solver)
    print(sim.output.print_stdout.file)
    pass


def test_make(sim):
    assert sim.make.exec(["mesh", "compile"])
    assert sim.make.exec(["run"], dryrun=True)


@pytest.mark.slow
def test_make_run(sim):
    # Run in foreground
    assert sim.make.exec(["srun"])

    # test outputs
    dt = sim.output.print_stdout.dt
    # number of time steps executed, see conftest.py
    assert dt.size == 9
    
    # check if simulation can be restarted
    restart_params = prepare_for_restart(sim.path_run)
    