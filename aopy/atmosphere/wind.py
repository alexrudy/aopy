# -*- coding: utf-8 -*-
# 
#  blowingscreen.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-16.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
"""
:mod:`atmosphere.wind <aopy.atmosphere.wind>` – Blowing Komolgorov Screens
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
    :param float du: pixel size, in meters
    :param int nsh: Number of subharmonics. (default``=0`` for no subharmonics)
    
    To use this class, you must instantiate it, and then call :meth:`setup`. Since :meth:`setup` returns the instance, you can do::
        
        screen = BlowingScreen((10,10),r0=2,vel=[1.0,0.0]).setup()
    
    """ 
    def __init__(self, shape, r0, seed=None, vel=None, tmax=100, **kwargs):
        super(BlowingScreen, self).__init__(shape, r0, seed, **kwargs)
        if vel is None:
            vel = [1.0,0.0]
        self._vel = np.array(vel)
        self._vel.flags.writeable = False
        self._tmax = tmax
        self._outshape = tuple(np.copy(self.shape).astype(np.int))
        self._shape = tuple((np.array(self.shape) + np.abs(self._vel) * np.ceil(self._tmax / self._du)).astype(np.int))
        self._all = None
    
    
    @property
    def velocity(self):
        """The wind velocity vector for this screen. A 1-dimensional array with ``[v_x,v_y]``. **Read-Only**"""
        return self._vel
    
    def setup(self):
        """Generates the filter and the screen over which the system will interpolate.
        
        :returns: A reference to this instance (``self``)
        """
        self._generate_filter()
        self._generate_screen()
        return self
        
    def get_screen(self,t):
        """Get a screen at time `t`.
        
        :param int t: The timestep at which to retrieve the screen.
        :returns: The screen for this timestep.
        """
        import scipy.ndimage.interpolation
        shift = t * self._vel / self._du
        shifted = scipy.ndimage.interpolation.shift(
            input = self.screen,
            shift = shift,
            order = 1, #Linear interpolation!
            mode = 'wrap', #So we go in circles!
        )
        n,m = self._outshape
        return shifted[:n,:m]
        
    def __len__(self):
        """Length"""
        return self._tmax
        
    @property
    def screens(self):
        """An iterator through this screen over time. 
        
        Use like::
            
            for screen in blowing.screens:
                print(screen[0,0])
            
        
        """
        for _t in range(self._tmax):
            yield self.get_screen(_t)
            
    @property
    def all(self):
        """An array of all possible screens. This array is lazily evaluated. **Read-Only**"""
        if self._all is not None:
            return self._all
        else:
            self._all = np.zeros((self._tmax,)+self._outshape)
            for t in self.looper(range(self._tmax)):
                self._all[t,...] = self.get_screen(t)
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
    :param float du: Pixel size, in meters.
    :param int nsh: Number of subharmonics. (default``=0`` for no subharmonics)
    
    To use this class, you must instantiate it, and then call :meth:`setup`. Since :meth:`setup` returns the instance, you can do::
        
        screen = ManyLayerScreen((10,10),r0=2,vel=[1.0,0.0]).setup()
    
    """ 
    def __init__(self, shape, r0, seed=None, vel=None, strength=None, **kwargs):
        if vel is None:
            vel = np.array([[1.0,0.0]])
        vel = np.atleast_2d(vel)
        
        if strength is None:
            strength = np.ones((vel.shape[0],))
        
        if vel.shape[0] != strength.shape[0]:
            raise ValueError("Must provide same number of layer strengths as layer velocities!")
        
        self._strength = strength
        
        super(ManyLayerScreen, self).__init__(shape, r0, seed, vel=None, **kwargs)
        
        self._vel = vel
        self._shape = tuple(np.array(self.shape) + np.abs(np.max(self._vel,axis=0)) * np.ceil(self._tmax / self._du).astype(np.int))
        
        self._screens = np.zeros((self._vel.shape[0],)+self._shape)
        
    def _generate_screen(self):
        """Use :meth:`setup` to control this method.
        
        Generate the actual screen, using the filters produced by :meth:`_generate_filter`
        
        :param seed: The random number generator seed.
        """
        norm = np.sum(self._strength)
        for i, strength in enumerate(self._strength):
            self._screens[i,...] = _generate_screen(self._filter,self.seed,self._shf,self.du) * (strength/norm)
        
    def get_screen(self,t):
        """Get a screen at time `t`.
        
        :param int t: The timestep at which to retrieve the screen.
        :returns: The screen for this timestep.
        """
        import scipy.ndimage.interpolation
        shifts = t * self._vel / self._du
        shifted = np.zeros_like(self._screens)
        for i,(shift,screen) in enumerate(zip(shifts,self._screens)):
            shifted[i,...] = scipy.ndimage.interpolation.shift(
                input = screen,
                shift = shift,
                order = 1, #Linear interpolation!
                mode = 'wrap', #So we go in circles!
            )
        n,m = self._outshape
        shifted = np.sum(shifted[:,:n,:m],axis=0)
        return shifted
        