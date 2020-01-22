from eturb.solvers.abl import Simul


def test_init():
    params = Simul.create_default_params()
    Simul(params)
