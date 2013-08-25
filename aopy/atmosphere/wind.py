# -*- coding: utf-8 -*-
# 
#  blowingscreen.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-16.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
"""
:mod:`~aopy.atmosphere.wind` – Blowing Komolgorov Screens
==========================================================================

This module contains screens which can appear to "blow" through an aperture. Screens
can be composed of multiple blowing layers, or a single layer.

:class:`BlowingScreen` – Single Layer Wind
------------------------------------------

.. autoclass::
    BlowingScreen
    :members:
    :inherited-members:


:class:`ManyLayerScreen` – Many Layer Wind
------------------------------------------

.. autoclass::
    ManyLayerScreen
    :members:
    :inherited-members:

"""

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

# Python
import warnings, logging

# Numpy
import numpy as np

import astropy.units as u
from ..util.units import ensure_quantity
from ..util.math import fast_shift

from .screen import Screen, _generate_screen

class BlowingScreen(Screen):
    """A blowing Kolmolgorov Phase Screen Class. This class builds a Komologorv Filter and then generates a phase screen for that filter. The phase screen is then read out in parts (interpolated, where necessary) so that it appears to "blow" in a frozen-flow style across as screen of the desired shape. Once a single phase screen has been generated, it is cached in the object. For a new phase screen, set a different :attr:`seed` value.
    
    :param tuple shape: The shape of the screen (x,y), as a tuple.
    :param float r0: :math:`r_0` fried parameter for the screen, in meters
    :param float L0: :math:`L_0` outer scale for the screen, in meters
    :param int seed: Random number generator seed for :mod:`numpy.random`
    :param list vel: The velocity, ``[v_x,v_y]``, in meters/second
    :param float tmax: The amount of time to generate phase for, in seconds. Timesteps 
        beyond this value will see the screen wrapped around and started from the beginning.
    :param float dt: Timestep size, in seconds.
    :param float du: pixel size, in meters
    :param int nsh: Number of subharmonics. (default``=0`` for no subharmonics)
    
    """ 
    def __init__(self, shape, r0, seed=None, vel=None, tmax=100, dt=1, delay=False, order=3, **kwargs):
        super(BlowingScreen, self).__init__(shape, r0, seed, delay=True, **kwargs)
        # Sanitize Velocities
        if vel is None:
            vel = [1.0,0.0]
        vel = np.array(vel)
        if vel.shape != (2,):
            raise ValueError("Velocity must have shape (2,), not {}".format(vel.shape))
        
        # Setup instance variables
        self._vel = ensure_quantity(vel,unit=u.meter/u.second)
        self._tmax = ensure_quantity(tmax, unit=u.second)
        self._dt = ensure_quantity(dt, unit=u.second)
        self._outshape = tuple(np.copy(self.shape).astype(np.int))
        self._stepshape = tuple(np.fix((np.array(self.shape) + np.abs(self._vel) * np.ceil(1.0 * u.s / self._du)).to('').value).astype(np.int))
        self._shape = tuple(np.fix((np.array(self.shape) + np.abs(self._vel) * np.ceil(self._tmax / self._du)).to('').value).astype(np.int))
        self._order = order
        
        # Setup generated variables
        self._all = None
        self._ti = 0
        self._filtered_screen = None
        if not delay:
            self.setup()
    
    # Instance variable setup
    _vel = None
    _tmax = None
    _dt = None
    _outshape = tuple()
    _shape = tuple()
    _all = None
    _order = None
    _ti = None
    _filtered_screen = None
    
    @property
    def velocity(self):
        """The wind velocity vector for this screen. A 1-dimensional array with ``[v_x,v_y]``. **Read-Only**"""
        return self._vel
        
    @property
    def dt(self):
        """Timestep"""
        return self._dt
        
    @property
    def tmax(self):
        """Total Time"""
        return self._tmax
        
    @property
    def counter(self):
        """The current counter value"""
        return self._ti
        
    @counter.setter
    def counter(self,value):
        if value < 2*len(self):
            self._ti = value % len(self)
        else:
            raise ValueError("Cannot set loop counter greater than length {}".format(len(self)))
    
    def setup(self):
        """Generates the filter and the screen over which the system will interpolate.
        
        :returns: A reference to this instance (``self``)
        """
        self._generate_filter()
        self._generate_screen()
        return self
        
    def _generate_screen(self):
        """Ensure filtered screen is generated."""
        import scipy.ndimage.interpolation
        super(BlowingScreen, self)._generate_screen()
        self._filtered_screen = scipy.ndimage.interpolation.spline_filter(self._screen, self._order)
        
        
    def get_screen(self,t):
        """Get a screen at time `t`.
        
        :param int t: The timestep at which to retrieve the screen.
        :returns: The screen for this timestep.
        """
        import scipy.ndimage.interpolation
        shift = (ensure_quantity(t,u.second) * self._vel / self._du).to('').value
        shifted = fast_shift(
            source = self._filtered_screen,
            shift = shift,
            order = self._order,
            mode = 'wrap', #So we go in circles!
            prefilter = False, #Because we already filtered it!
            shape = self._outshape,
        )
        return shifted
        
    @property
    def screen(self):
        """Counter movement screen"""
        self.counter += 1
        return self.get_screen(self._ti * self._dt)
        
    def __len__(self):
        """Length"""
        return (self._tmax // self._dt).to('').value
        
    @property
    def screens(self):
        """An iterator through this screen over time. 
        
        Use like::
            
            for screen in blowing.screens:
                print(screen[0,0])
            
        
        """
        for _i in range(len(self)):
            yield self.screen
            
    @property
    def all(self):
        """An array of all possible screens. This array is lazily evaluated. **Read-Only**"""
        if self._all is not None:
            return self._all
        else:
            self._all = np.zeros((len(self),)+self._outshape)
            for ti in self.looper(range(len(self))):
                self._all[ti,...] = self.get_screen(ti * self._dt)
            self._all.flags.writeable = False
            return self._all

class ManyLayerScreen(BlowingScreen):
    """A blowing Kolmolgorov Phase Screen Class with multiple layer support. This class builds a Komologorv Filter and then generates a phase screen for each layer with that filter. The phase screens are then read out in parts (interpolated, where necessary) so that they appears to "blow" in a frozen-flow style across as screen of the desired shape. Once a set of phase screens has been generated, they are cached in the object. For a new phase screen, set a different :attr:`seed` value.
    
    :param tuple shape: The shape of the screen (x,y), as a tuple.
    :param float r0: :math:`r_0` fried parameter for the screen.
    :param float L0: :math:`L_0` outer scale for the screen.
    :param int seed: Random number generator seed for :mod:`numpy.random`
    :param array vel: The velocity array, at least 2-dimensional, ``[[v_x1,v_y1],[v_x2,v_y2]]``
    :param array strength: The relative strengths of each layer. (by default, all layers have the same strength.)
    :param float tmax: The amount of time to generate phase for, in seconds. Timesteps 
        beyond this value will see the screen wrapped around and started from the beginning.
    :param float dt: Timestep size, in seconds.
    :param float du: Pixel size, in meters.
    :param int nsh: Number of subharmonics. (default``=0`` for no subharmonics)
    
    """ 
    def __init__(self, shape, r0, seed=None, vel=None, strength=None, delay=False, **kwargs):
        if vel is None:
            vel = np.array([[1.0,0.0]])
        vel = ensure_quantity(np.atleast_2d(vel),unit=u.meter/u.second)
        
        if strength is None:
            strength = np.ones((vel.shape[0],))
        else:
            strength = np.array(strength)
        if vel.shape[0] != strength.shape[0]:
            raise ValueError("Must provide same number of layer strengths as layer velocities!")
        
        self._strength = strength
        
        super(ManyLayerScreen, self).__init__(shape, r0, seed, vel=None, delay=True, **kwargs)
        
        self._vel = vel
        self._shape = tuple(np.fix((np.array(self.shape) + np.abs(np.max(self._vel,axis=0)) * np.ceil(self._tmax / self._du)).to('').value))
        
        self._screens = np.zeros((self._vel.shape[0],)+self._shape)
        self._filtered_screens = np.zeros_like(self._screens)
        
        if not delay:
            self.setup()
        
    def _generate_screen(self):
        """Use :meth:`setup` to control this method.
        
        Generate the actual screen, using the filters produced by :meth:`_generate_filter`
        
        :param seed: The random number generator seed.
        """
        import scipy.ndimage.interpolation
        norm = np.sum(self._strength)
        for i, strength in enumerate(self._strength):
            screen = _generate_screen(self._filter, self.seed, self._shf, self.du.to('meter').value) * (strength/norm)
            self._screens[i,...] = screen
            self._filtered_screens[i,...] = scipy.ndimage.interpolation.spline_filter(screen, self._order)
            
        
        
    def get_screen(self,t):
        """Get a screen at time `t`.
        
        :param int t: The timestep at which to retrieve the screen.
        :returns: The screen for this timestep.
        """
        import scipy.ndimage.interpolation
        shifts = (ensure_quantity(t,u.second) * self._vel / self._du).to(1).value
        shifted = np.zeros((len(shifts),) + self._outshape)
        for i,(shift,screen) in enumerate(zip(shifts, self._filtered_screens)):
            shifted[i,...] = fast_shift(
                source = screen,
                shift = shift,
                order = self._order,
                mode = 'wrap', #So we go in circles!
                prefilter = False, #Because we already filtered it!
                # prefilter=True means **apply the prefilter**. Since we are using filtered screens, don't worry!
                shape = self._outshape,
            )
        shifted = np.sum(shifted, axis=0)
        return shifted
        