"""Jinja templates for rendering case files

Provides the following Template_ instances:

- ``box``
- ``size``

.. _Template: https://jinja.palletsprojects.com/en/2.10.x/api/#jinja2.Template

"""
import jinja2


env = jinja2.Environment(
    loader=jinja2.PackageLoader('abl', 'templates'),
)

box = env.get_template("abl.box.j2")
size = env.get_template("SIZE.j2")