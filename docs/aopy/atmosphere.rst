
:mod:`atmosphere <aopy.atmosphere>` – Modeling a Komolgorov Atmosphere
======================================================================

This module builds model atmospheric phase screens. The phase screens simulate
the phase delay found in a single wavefront of light which propogates through
Komolgorov turbulence. The generation of phase screens is split into two separate
submodules: :mod:`aopy.atmosphere.screen`, which builds and outputs static phase
screens

Static Kolmolgorov phase screens
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


Testing :mod:`aopy.atmosphere` against IDL
------------------------------------------

Using :mod:`pIDLy` to run and communicate with an IDL interpreter,
``nosetests`` verifies that functions in :mod:`aopy.atmosphere.screen`
produce outputs consistent with ``screengen.pro``. You can also verify
this result in more detail (noisier output...) using the script ``test/screen.py``
which does similar comparisons.

.. warning::
    The testing uses IDL's ``randn`` function to generate consistent random values
    for comparison between python and IDL. In order for this to work properly,
    ``screengen.pro`` was modified: A new function ``screengen_fn`` was defined,
    identical to ``screengen_f``, except that ``screengen_fn`` accepts a noise vector
    for the subharmonic values, where ``screengen_f`` generates them on-the-fly.



Internal Phase Screen Functions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

These functions are the underlying algorithm for :class:`Screen`. 
It is not recommended that you use them, but they are useful for testing
this module against the original ``screengen.pro``, as is done in ``examples/screengen.py``

.. automodule::
    aopy.atmosphere.wind


.. automodapi::
    aopy.atmosphere