import pytest


def test_init(sim):
    pass


def test_make(sim):
    assert sim.make.exec(["mesh", "compile"])
    assert sim.make.exec(["run"], dryrun=True)


@pytest.mark.slow
def test_make_run(sim):
    assert sim.make.exec()
