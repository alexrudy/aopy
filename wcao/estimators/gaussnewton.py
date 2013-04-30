# -*- coding: utf-8 -*-
# 
#  gaussnewton.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-18.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np

from aopy.util.math import depiston
from aopy.aperture import Aperture
from aopy.util.log import LTypeFilter, LType
from .core import BaseEstimator

from pyshell.core import Struct

class GaussNewtonEstimator(BaseEstimator):
    """A basic Gauss-Newton Estimator"""
    def __init__(self, fft=False, idl=False, order=3, iterations=1, shift_mode='nearest'):
        super(GaussNewtonEstimator, self).__init__()
        self.fft = fft
        self.idl = idl
        self.iterations = iterations
        self._wind = np.array([[0,0]]).astype(np.float)
        self._nlayers = 1
        self.shift = Struct()
        self.shift.mode = shift_mode
        self.shift.order = order

        
    
    @property
    def fft(self):
        """Use fft?"""
        return self._fft
        
    @fft.setter
    def fft(self,value):
        """docstring for fft"""
        import scipy.signal
        if value is True:
            self._fft = value
            self._convolve = scipy.signal.fftconvolve
        elif value is False:
            self._fft = value
            self._convolve = scipy.signal.convolve
    
    @property
    def wind(self):
        """docstring for wind"""
        if self.nlayers == 1:
            return self._wind[0,:]
        else:
            return self._wind[:]
    
    @property
    def nlayers(self):
        """Return the number of layers"""
        return self._nlayers
    
    def setup(self,aperture,inner=None):
        """docstring for setup"""
        self.aperture = Aperture(aperture) 
        if inner is not None:
            self.aperture.edgemask = np.array(inner)
        
        # Intialize method arrays (to prevent them from reallocating)
        self._GradI = np.zeros((2,)+self.aperture.shape)
        self._DeltaI = np.zeros(self.aperture.shape)
        
        # Track dotted method names
        import scipy.ndimage.interpolation
        self.shift.func = scipy.ndimage.interpolation.shift
        
        import numpy.linalg
        self._inv = numpy.linalg.inv
        
        return self
    
    def validate(self,current,previous,wind=None):
        """Takes the same arguments as :meth:`estimate`, but ensures that they are valid first."""
        if current.shape != previous.shape:
            raise ValueError("Current {0!s} and Previous {0!s} phase must have the same shape.".format(
                current.shape, previous.shape
            ))
        if self.aperture.shape != current.shape:
            raise ValueError("Current {0!s} phase and Aperture {0!s} must have the same shape.".format(
                current.shape, self.aperture.shape
            ))
            
    
    def estimate(self,current,previous,wind=None):
        """docstring for estimate"""
        # Normalize inputs and place them in the local namespace.
        wind = self._wind if wind is None else np.atleast_2d(wind)
        current = np.array(current).astype(np.float)
        previous = np.array(previous).astype(np.float)
        
        ap_every = self.aperture.pupil
        ap_inner = self.aperture.edgemask
        
        convolve = self._convolve
        inv = self._inv
        
        mode = self.shift.mode
        order = self.shift.order
        shift = self.shift.func
        
        GradI = self._GradI
        DeltaI = self._DeltaI
        
        denominator = np.zeros((2,2))
        
        # Create the Gradient Matrix (X,Y)
        gcurr = depiston(current,ap_every)
        kernel = np.array([[ -0.5, 0.0, 0.5 ]])
        GradI[0,:,:] = convolve(gcurr,kernel,mode='same') * ap_every * -1.0
        GradI[1,:,:] = convolve(gcurr,kernel.T,mode='same') * ap_every * -1.0
        
        if self.idl:
            # Aparently scipy.convolve returns values along the edges where IDL convol doesn't.
            #TODO: Examine when and where this is true!
            GradI[0,...,0] = 0.0
            GradI[0,...,-1] = 0.0
            GradI[1,0,...] = 0.0
            GradI[1,-1,...] = 0.0
        else:
            GradI[0,...] *= ap_inner
            GradI[1,...] *= ap_inner
        
        # Setup a reference wavefront
        ref = depiston(current * ap_inner, ap_inner)
        
        for k in range(self.iterations):
            DeltaI = ref - depiston(shift(
                input = previous,
                shift = wind[0,::-1],
                mode = mode,
                order = order,
            ) * ap_inner, ap_inner)
            numerator = np.array([[np.sum(GradI[0,...]*DeltaI)],[np.sum(GradI[1,...]*DeltaI)]])

            denominator[0,0] = np.sum(GradI[0,...]*GradI[0,...])
            denominator[0,1] = np.sum(GradI[0,...]*GradI[1,...])
            denominator[1,0] = np.sum(GradI[1,...]*GradI[0,...])
            denominator[1,1] = np.sum(GradI[1,...]*GradI[1,...])
        
            d_wind = np.dot(-inv(denominator),numerator)
        
            wind[0] += d_wind[:,0]
        
        self._wind = np.copy(wind)
        return wind
        
    


def estimate_wind_gn(current,previous,aloc=None,
    aloc_inner=None,wind=None,max_it=1,linear=True,IDLMode=False,fft=False):
    """Estimates a wind direction given two frames, using a gauss-newton approach.
    
    :param current: The current phase
    :param previous: The previous timestep's phase
    :param aloc: Actuator locations (boolean array mask)
    :param aloc_inner: Locations of non-edge actuations (boolean array mask)
    :param wind: Wind prior, if none, assumed to be [0,0]
    :param max_it: Maximum number of Gauss-Newton iterations to conduct.
    :param linear: Wether to assume things are linear.
    """
    import scipy.signal
    import scipy.ndimage.interpolation
    import numpy.linalg
    from aopy.util.math import edgemask
    
    wind = np.array([0.0,0.0]) if wind is None else wind
    wind = wind.astype(np.float)
    aloc = np.ones_like(current) if aloc is None else aloc
    aloc_inner = (aloc_inner if aloc_inner is not None else edgemask(aloc)).astype(np.bool)
    
    GradI = np.zeros((2,)+current.shape)
    DeltaI = np.zeros(current.shape)
    
    gcurr = depiston(current,aloc)
    kernel = np.array([[ -0.5, 0.0, 0.5 ]])
    convolve = scipy.signal.fftconvolve if fft else scipy.signal.convolve
    GradI[0,:,:] = convolve(gcurr,kernel,mode='same') * aloc * -1
    GradI[1,:,:] = convolve(gcurr,kernel.T,mode='same') * aloc * -1
    
    if IDLMode:
        # Aparently scipy.convolve returns values along the edges where IDL convol doesn't.
        #TODO: Examine when and where this is true!
        GradI[0,...,0] = 0.0
        GradI[0,...,-1] = 0.0
        GradI[1,0,...] = 0.0
        GradI[1,-1,...] = 0.0
        
    else:
        GradI[0,...] *= aloc_inner
        GradI[1,...] *= aloc_inner
    
    ref = depiston(current * aloc_inner,aloc_inner)
    for k in range(max_it):
        DeltaI = ref - depiston(scipy.ndimage.interpolation.shift(
            input = previous,
            shift = wind[::-1],
            mode = 'nearest',
            order = 1,
        ) * aloc_inner, aloc_inner)
        numerator = np.array([[np.sum(GradI[0,...]*DeltaI)],[np.sum(GradI[1,...]*DeltaI)]])

        denominator = np.zeros((2,2))
        denominator[0,0] = np.sum(GradI[0,...]*GradI[0,...])
        denominator[0,1] = np.sum(GradI[0,...]*GradI[1,...])
        denominator[1,0] = np.sum(GradI[1,...]*GradI[0,...])
        denominator[1,1] = np.sum(GradI[1,...]*GradI[1,...])
        
        d_wind = np.dot(-numpy.linalg.inv(denominator),numerator)
        
        wind += d_wind[:,0]
        
    return wind