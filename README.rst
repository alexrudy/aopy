AOPY - AdaptiveOpticsPYthon
===========================

This is a module for doing Adaptive-Optics-y things in Python. There are several subdirectories in this repository.

Layout
------

* ``aopy`` - Basic Adaptive Optics routines. These directories will hold python ports of Don Gavel's libraries. This should eventualy be split into its own library.
* ``docs`` - Sphinx based documentation for all of the python code in here.
* ``external`` - External python libraries that are used.
* ``IDL`` - IDL libraries and programs.
* ``plugins`` - Sub-modules which perform specific tasks within the WCAO framework
* ``tests`` - Python unit tests.
* ``wcao`` - Wind-corrective-adaptive-optics, the python wind estimation framework



Requirements
------------

This module was written in Python 2.7, and only tested on Python 2.7

This module requires Numpy and Scipy for algorithms, and uses Matplotlib for plotting. It is often easiest to install these three modules on their own, before installing ``aopy``. You should be able to install any dependents you need using `pip <https://pypi.python.org/pypi/pip>`_.

* `numpy <http://www.numpy.org>`_
* `scipy <http://www.scipy.org>`_
* `matplotlib <http://matplotlib.org>`_

This module *might* use some components from the `pyshell <http://github.com/alexrudy/pyshell>`_ library, although I've tried to avoid that. If it does use any pyshell tools, please let me know, and I'll try to eliminate them if they are unnecessary.

This module also does depend on `astropy <http://astropy.org/>`_, but that installation should be handled automatically by ``aopy``. (Actually, all of the installations could be handled by ``aopy``, but there are some tricky aspects to installing ``matplotlib`` that make this perhaps a bad idea.)

Installation
------------

Once you have Numpy, Scipy and Matplotlib installed, try::
    
    $ python setup.py install
    
to install ``aopy``. 

Examples
--------

You can see some working examples in the ``examples`` directory:

* ``depiston`` uses ``pIDLy`` to test the ``aopy.util.math.depiston`` function.
* ``make_wind`` makes a multi-layer phase screen, saving each time step to an array and then making a fits file.
* ``play_screens`` shows a movie of a pair of translating phase screens stacked on top of each other.

Documentation
-------------

To build the documentation, you'll need `sphinx <http://sphinx-doc.org/latest/index.html>`_. Then you can run::
    
    $ cd docs/
    $ make html
     
When you run this, the HTML documentation is stored in ``docs/_build/html/``, so you can open the homepage from ``docs/_build/html/index.html``.

Testing
-------

For testing, you'll need:

* `nosetests <https://nose.readthedocs.org/en/latest/index.html>`_
* `pIDLy <https://github.com/anthonyjsmith/pIDLy>`_

Then, from the source directory, try::
    
    $ python setup.py nosetests
    

You should also check out ``tests/screens.py``, which is a testing script for comparing phase screens between python and IDL. Its functionality is duplicated in the ``noestests`` suite, but ``tests/screens.py`` is a more verbose version.
