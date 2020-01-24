import pytest


def test_init(sim):
    pass


def test_make(sim):
    sim.make.exec(["mesh", "compile"])
    sim.make.exec(["run"], dryrun=True)


@pytest.mark.slow
def test_make_run(sim):
    sim.make.exec()
