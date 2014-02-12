# -*- coding: utf-8 -*-
"""
This module contains several subcomponents for modeling Komolgorov Turbulence, specifically in our atmosphere.

- :mod:`aopy.atmosphere.screen` contains components for modeling single Komolgorov screens.
- :mod:`aopy.atmosphere.wind` contains components for modeling frozen-flow Komolgorov turbulence.

This module exposes :class:`~aopy.atmosphere.screen.Screen` and :class:`~aopy.atmosphere.wind.ManyLayerScreen`::
    
    from aopy.atmosphere import Screen, ManyLayerScreen
    
    screen = Screen((10,10),r0=10,seed=2)
    
    wind = ManyLayerScreen((10,10),r0=10,vel=[[1,0],[3,3]])
"""

from .screen import Screen
from .wind import ManyLayerScreen

__all__ = ['Screen', 'ManyLayerScreen']