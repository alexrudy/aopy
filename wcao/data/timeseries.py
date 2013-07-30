# -*- coding: utf-8 -*-
# 
#  timeseries.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-01.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np
import astropy.units as u

import collections

from .estimator import WCAOEstimate

from aopy.util.units import ensure_quantity


class WCAOTimeseries(WCAOEstimate):
    """A representation of WCAO timeseries data"""
    def __init__(self,*args,**kwargs):
        super(WCAOTimeseries, self).__init__(*args, **kwargs)
        self.clip = False
        
    def init_data(self,data=None,time=None,timestep=None):
        """Initialize and validate timeseires data"""
        if data is None:
            return
        data = np.array(data)
        if data.ndim != 3:
            raise ValueError("{0:s}-type data should have 3 dimensions: (time,layer,x/y). data.ndim={1.ndim:d}".format(self.arraytype,data))
        if data.shape[2] != 2:
            raise ValueError("{0:s}-type data should have shape (ntime,nlayers,2(x/y)). data.shape={1.shape!r}".format(self.arraytype,data))
        self._data = data
        
        if timestep is None:
            self._timestep = ensure_quantity(timestep,u.s)
        
        if time is None:
            self._time = np.arange(self.ntime) * self._timestep.to('s')
        else:
            time = ensure_quantity(time, u.s)
            if time.ndim != 1 or time.shape[0] != self._data.shape[0]
                raise ValueError("{0:s}-type time should match the shape of the first axes of data. Got {!r}, expected {!r}".format(
                    self.arraytype, time.shape, tuple(self._data.shape[0])
                ))
            self._time = time
            self._timestep = np.diff(self._time[:2]) if np.all_close(np.diff(self._time),np.diff(self._time[:2])) else None
        
        
    
    def apply_clip(self,data):
        """docstring for apply_clip"""
        if isinstance(self.clip,slice):
            return data[self.clip]
        else:
            return data
    
    @property
    def data(self):
        """docstring for data"""
        return self.apply_clip(self._data)
        
    @property
    def nlayers(self):
        """Number of layers in this data"""
        return self.data.shape[1]
        
    @property
    def ntime(self):
        """Number of timesteps"""
        return self.data.shape[0]
        
    @property
    def time(self):
        """The time array"""
        return self.apply_clip(self._time)
        
    @property
    def timestep(self):
        """The step size of the time array, if it is well defined."""
        return self._timestep
    
    def smoothed(self,window,mode='flat'):
        """docstring for smoothed"""
        from aopy.util.math import smooth
        rv = np.zeros_like(self.data)
        for layer in range(self.nlayers):
            for i in [0,1]:
                rv[:,layer,i] = self.apply_clip(smooth(self._data[:,layer,i],window,mode))
        return rv
    

