# -*- coding: utf-8 -*-
"""
:mod:`atmosphere <aopy.atmosphere>` – Modeling a Komolgorov Atmosphere
======================================================================

This module contains several subcomponents for modeling Komolgorov Turbulence, specifically in our atmosphere.

- :mod:`aopy.atmosphere.screen` contains components for modeling single Komolgorov screens.
- :mod:`aopy.atmosphere.wind` contains components for modeling frozen-flow Komolgorov turbulence.

This module exposes :class:`Screen` and :class:`ManyLayerScreen`::
    
    from aopy.atmosphere import Screen,ManyLayerScreen
    
    screen = Screen((10,10),r0=10,seed=2).setup()
    
    wind = ManyLayerScreen((10,10),r0=10,vel=[[1,0],[3,3]]).setup()
    
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
"""

from .screen import Screen
from .wind import ManyLayerScreen

__all__ = ['Screen','ManyLayerScreen']