# Developer guide

To install in development mode:

```sh
pip install -e '.[dev]'
```

## General guidelines

* **Editor**: Use an editor which supports [EditorConfig](http://editorconfig.org/)
* **Style guide**: Follow [Fortran best
  practices](https://www.fortran90.org/src/best-practices.html). For the Python
  code, the tool `black`, `isort` and `flake8` are used. Install `pre-commit`
  to automate this via git hooks.

  ```sh
  pre-commit install
  ```

* **Branching model**: The development uses branches and pull-requests for experimental features. We
  also rely on [git submodules](https://www.git-scm.com/docs/git-submodule) to
  track other libraries. The following branches are important:

  * `snek5000-abl`:
    * `master`: main branch
    * `develop`: development branch
  * `lib/Nek5000`:
    * `master`: upstream branch
    * `stable`: main branch tracking the stable version 17
    * `develop`: development branch

  The following make working with submodules easy and ensures consistency:
  ```sh
  # Enable recursion for relevant commands, such that
  # regular commands recurse into submodules by default
  git config submodule.recurse true
  ```

* **Testing**: [Run `pytest`](https://pytest.readthedocs.io/) from the
  top-level directory. The test-cases can be found under `tests/` directory.
* **Debugging**: Set the environment variable:
  ```bash
  export SNEK_DEBUG=true
  ```
  to activate debugging logs and longer tests.

## Vim

Vim users could benefit by setting:
```vim
set secure exrc
```
This sources the `.exrc` file which comes along with the repository and
enables syntax highlighting for file extensions used in `lib/Nek5000`.
