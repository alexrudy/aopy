.. Adaptive Optics Py documentation master file, created by
   sphinx-quickstart on Wed May  1 13:28:11 2013.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to the AOPY Suite
=========================

The AOPY Suite contains several modules for working with adaptive optics systems and tools in Python.

* :mod:`aopy` – Adaptive Optics in Python: The base tools for working with an AO system on a simple level.
* :mod:`wcao` – Wind-Controlled Adaptive Optics: Frameworks for developing and testing wind-aware controllers.
* Plugins – A series of side-moduels for :mod:`wcao` which implement different methods.

AOPY - Adaptive Optics in Python
================================

Contents:

.. toctree::
   :maxdepth: 2
   
   aopy/index
   aopy/atmosphere
   aopy/aperture
   aopy/wavefront
   aopy/util.math


WCAO - Wind Controlled Adaptive Optics
======================================

Contents:

.. toctree::
    :maxdepth: 2

    wcao/index
    wcao/wcao.data
    wcao/wcao.estimators


Plugins – Extensions to WCAO
============================

Contents:

.. toctree::
    :maxdepth: 2
    
    plugins/index
    plugins/keck


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`

