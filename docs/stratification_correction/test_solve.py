import math
from functools import partial

import strat_correct as py
import strat_correct_f as ftn

isclose = partial(math.isclose, rel_tol=1e-6)


def test_python_fortran():
    xi = 0.05 / 0.1
    assert isclose(py.psi_m_stable(xi), ftn.psi_m_stable(xi))
    assert isclose(py.psi_m_unstable(-xi), ftn.psi_m_unstable(-xi))
    assert isclose(py.psi_h_unstable(-xi), ftn.psi_h_unstable(-xi))

    # unstable
    test_args = [-0.15, 0.1, 1.0, 0.14]
    assert isclose(py.richardson(*test_args[:3]), ftn.richardson(*test_args[:3]))
    assert isclose(py.f_richardson(*test_args), ftn.f_richardson(*test_args))

    # stable
    test_args[0] *= -1
    assert isclose(py.richardson(*test_args[:3]), ftn.richardson(*test_args[:3]))
    assert isclose(py.f_richardson(*test_args), ftn.f_richardson(*test_args))
