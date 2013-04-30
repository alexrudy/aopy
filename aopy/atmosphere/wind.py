# -*- coding: utf-8 -*-
# 
#  blowingscreen.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-16.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

# Python
import warnings, logging

# Numpy
import numpy as np

from .atmosphere import Screen, generate_screen

class BlowingScreen(Screen):
    """Create a blowing screen.
    
    :param shape:
    :param r0:
    :param vel:
    :param tmax:
    """ 
    def __init__(self, shape, r0, seed=None, vel=None, tmax=100, **kwargs):
        super(BlowingScreen, self).__init__(shape, r0, seed, **kwargs)
        if vel is None:
            vel = [1.0,0.0]
        self._vel = np.array(vel)
        self._tmax = tmax
        self._outshape = np.copy(self.shape)
        self._shape = tuple(np.array(self.shape) + np.abs(self._vel) * self._tmax)
    
        
    @property
    def velocity(self):
        """docstring for velocity"""
        return self._vel
    
    def setup(self):
        """Makes the screen over which the system will interpolate."""
        self.generate_filter()
        self.generate_screen()
        return self
        
    def get_screen(self,t):
        """Get a screen at time t."""
        import scipy.ndimage.interpolation
        shift = t * self._vel
        shifted = scipy.ndimage.interpolation.shift(
            input = self.screen,
            shift = shift,
            order = 1, #Linear interpolation!
            mode = 'wrap', #So we go in circles!
        )
        n,m = self._outshape
        return shifted[:n,:m]
        
    @property
    def screens(self):
        """Iterate through a screen over integer screen points."""
        for _t in range(self._tmax):
            yield self.get_screen(_t)

class ManyLayerScreen(BlowingScreen):
    """docstring for ManyLayerScreen"""
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
        self._shape = tuple(np.array(self.shape) + np.abs(np.max(self._vel,axis=1)) * self._tmax)
        
        self._screens = np.zeros((self._vel.shape[0],)+self._shape)
        
    def setup(self):
        """Get the screens up and running."""
        self.generate_filter()
        norm = np.sum(self._strength)
        for i, strength in enumerate(self._strength):
            self._screens[i,...] = generate_screen(self._filter,self.seed,self._shf,self.du) * np.sqrt(strength/norm)
        return self
        
    def get_screen(self,t):
        """docstring for get_screen"""
        import scipy.ndimage.interpolation
        shifts = t * self._vel
        shifted = np.zeros_like(self._screens)
        for i,(shift,screen) in enumerate(zip(shifts,self._screens)):
            shifted[i,...] = scipy.ndimage.interpolation.shift(
                input = screen,
                shift = shift,
                order = 1, #Linear interpolation!
                mode = 'wrap', #So we go in circles!
            )
        n,m = self._outshape
        shifted = np.sum(shifted,axis=0)
        return shifted[:n,:m]
        