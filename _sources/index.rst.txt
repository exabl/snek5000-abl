.. snek5000-abl documentation master file, created by
   sphinx-quickstart on Wed Dec 25 01:55:26 2019.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to snek5000-*abl*'s documentation!
===========================================

The ABL_ project is an interdisciplinary effort to model the atmospheric
boundary layer using Nek5000_. This documentation describes the Fortran user
code and its Python interface made using snek5000_'s API.

.. raw:: html


   <!--
      Icon derived from "wind slap icon" by Lorc. Available at
      https://game-icons.net/1x1/lorc/wind-slap.html .
      License: https://creativecommons.org/licenses/by/3.0/
   -->
   <img style="float: right;" src="_static/icon.svg" width="100rem"/>

+------------+----------------------------------------------------+
| Repository | https://github.com/exabl/snek5000-abl              |
+------------+----------------------------------------------------+
| Version    |                                       |release|    |
+------------+----------------------------------------------------+

.. toctree::
   :maxdepth: 2
   :caption: Getting Started

   README

.. toctree::
   :maxdepth: 2
   :caption: User Guide

   abl
   framework
   nek5000

.. autosummary::
   :toctree: _generated/

   abl

.. toctree::
   :maxdepth: 1
   :caption: Help & Reference

   roadmap
   validation
   boundary_cond
   filtering
   CONTRIBUTING
   CHANGELOG
   license

Links
=====

.. * :ref:`Upstream documentation for Nek5000 <nek:genindex>`
.. Strange intersphinx bug: WARNING: undefined label: nek:genindex (if the link has no caption the label must precede a section header)

* Nek5000_ documentation
* `KTH framework documentation <https://kth-nek5000.github.io/KTH_Framework>`_
* snek5000_ documentation
* `pymech documentation <https://pymech.readthedocs.io>`_

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
* `Documentation produced with Doxygen <doxygen/modules.html>`_

.. _ABL: https://e-science.se/people-and-research/projects/exabl/
.. _Nek5000: https://nek5000.github.io/NekDoc/appendix.html
.. _snek5000: https://snek5000.readthedocs.io
