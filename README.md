# snek5000-abl

[![](https://github.com/exabl/snek5000-abl/workflows/Tests/badge.svg)](https://github.com/exabl/snek5000-abl/actions?workflow=Tests)
[![](https://github.com/exabl/snek5000-abl/workflows/Docs/badge.svg)](https://github.com/exabl/snek5000-abl/actions?workflow=Docs)

<!-- badges -->

Simulations of **turbulent** atmospheric boundary layer using
[snek5000](https://snek5000.readthedocs.io).

**Documentation**: <https://exabl.github.io/snek5000-abl/>

:::{warning}
The code is a prototype and far from ready for production runs. Some parts of
the code are well validated and some parts require rigorous testing. **Use it
with caution**. To know the detailed status of the code, checkout the
[roadmap](https://exabl.github.io/snek5000-abl/roadmap.html).
:::

## Quick start

Install using Python 3.8+ as follows:

    git clone --recursive https://github.com/exabl/snek5000-abl.git
    cd snek5000-abl
    pip install -e .

Activate necessary environment variables

    source activate.sh

Use the command line tool to launch / set / inspect the simulation parameters

    abl --help

## Tests
```sh
pip install -e '.[tests]'
# Run simple tests: including compilation
pytest
# Run slow tests: launches simulation
pytest --runslow
```
