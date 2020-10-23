"""Jinja templates for rendering case files

The templates are sourced from ``snek5000.assets`` subpackage. Alternatively it
can defined are sourced from this ``templates`` subpackage.

Provides the following Template_ instances:

- ``box``
- ``size``
- ``makefile_usr``

.. _Template: https://jinja.palletsprojects.com/en/2.10.x/api/#jinja2.Template

.. todo::

    Use length set as a user_param in abl.par file to extrude the mesh to
    double precision values.

"""
import jinja2

env = jinja2.Environment(
    loader=jinja2.PackageLoader("snek5000", "assets"), undefined=jinja2.StrictUndefined,
)

box = env.get_template("box.j2")
makefile_usr = env.get_template("makefile_usr.inc.j2")

env_abl = jinja2.Environment(
    loader=jinja2.PackageLoader("abl", "templates"), undefined=jinja2.StrictUndefined,
)

size = env_abl.get_template("SIZE.j2")
compile_sh = env_abl.get_template("compile.sh.j2")
