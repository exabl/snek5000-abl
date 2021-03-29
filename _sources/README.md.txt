# snek5000-abl

[![](https://github.com/exabl/snek5000-abl/workflows/Tests/badge.svg)](https://github.com/exabl/snek5000-abl/actions?workflow=Tests)
[![](https://github.com/exabl/snek5000-abl/workflows/Docs/badge.svg)](https://github.com/exabl/snek5000-abl/actions?workflow=Docs)

**Efficient** simulations of **turbulent** atmospheric boundary layer.

## Quick start

Install using Python 3.6+ as follows:

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
