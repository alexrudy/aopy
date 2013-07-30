# -*- coding: utf-8 -*-
# 
#  gaussnewton.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-18.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
"""
:mod:`wcao.estimators.gaussnewton` – An iterative Gauss-Newton estimator
------------------------------------------------------------------------


:class:`GaussNewtonEstimator`
*****************************

.. autoclass::
    GaussNewtonEstimator
    :members:

"""

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np

from aopy.util.math import depiston
from aopy.aperture import Aperture
from aopy.util.log import LTypeFilter, LType
from .core import BaseEstimator

from pyshell.core import Struct

class GaussNewtonEstimator(BaseEstimator):
    """A basic Gauss-Newton Estimator.
    
    :param bool fft: Use fast-fourier-transform convolutions (may be less accurate).
    :param bool idl: Normalize convolution results to look like IDL's. See :ref:`convolution`.
    :param int order: The order for the spline interpolation used.
    :param str shift_mode: The shift mode to use when the wind-shifter moves off of the array.
    
    """
    def __init__(self, fft=False, idl=False, order=3, iterations=1, shift_mode='nearest'):
        super(GaussNewtonEstimator, self).__init__()
        self._init_fft = fft
        self.idl = idl
        self.iterations = iterations
        self._wind = np.array([[0,0]]).astype(np.float)
        self._nlayers = 1
        self.shift = Struct()
        self.shift.mode = shift_mode
        self.shift.order = order

        
    
    @property
    def fft(self):
        """Use fftconvolve? See :func:`scipy.signal.fftconvolve` and :func:`scipy.signal.convolve`"""
        return self._fft
        
    @fft.setter
    def fft(self,value):
        """Set's the FFT value and _convolve function appropriately."""
        import scipy.signal
        if value is True:
            self._fft = value
            self._convolve = scipy.signal.fftconvolve
        elif value is False:
            self._fft = value
            self._convolve = scipy.signal.convolve
    
    
    @property
    def wind(self):
        """This is the latest wind estimate."""
        if self.nlayers == 1:
            return self._wind[0,:]
        else:
            return self._wind[:]
    
    @property
    def nlayers(self):
        """Return the number of layers this estimator is finding."""
        return self._nlayers
        
    @property
    def nt(self):
        """Number of timesteps"""
        return self._nt - self._ns - 1
    
    def setup(self,case,wind=None,nt=False,ns=False):
        """Perform initialization procedures for this plan which may be resource intensive. This includes deep imports into scipy and numpy.
        
        :param WCAOCase case: The WCAO Case object.
        :param ndarray wind: The guess wind velocity.
        :returns self: To make ``GNE = GaussNewtonEstimator().setup(aperture)`` possible.
        
        """
        self.case = case
        self._phase = self.case.telemetry.phase
        
        
        if wind is not None:
            self._wind = np.atleast2d(wind)
        
        self._nt = nt or self.case.telemetry.nt
        if ns >= self._nt:
            raise ValueError("Must start from at least one timestep behind the endpoint.")
        self._ns = ns or 0
        self._winds = np.zeros((self._nt,self.nlayers,2))
        
        
        self.aperture = self.case.telemetry.aperture
        # Intialize method arrays (to prevent them from reallocating)
        self._GradI = np.zeros((2,)+self.aperture.shape)
        self._DeltaI = np.zeros(self.aperture.shape)
        
        # Track dotted method names
        import scipy.ndimage.interpolation
        self.shift.func = scipy.ndimage.interpolation.shift
        
        import numpy.linalg
        self._inv = numpy.linalg.inv
        
        # Setup the convolution method.
        self.fft = self._init_fft
        
        self._n = 1
        
        return self
        
    def finish(self):
        """Finish the evaluation of this plan, cleaning up."""
        self._wind = np.array([[0,0]]).astype(np.float)
        
        # Drop arrays
        self._GradI = None
        self._DeltaI = None
        self._phase = None
        
        # Drop Results
        from wcao.data.estimator import WCAOTimeseries
        self.case.addresult(self._winds * self.case.subapd * self.case.rate ,WCAOTimeseries,"GN")
        self._winds = None
        
        # Drop Case
        self.case = None
        
        # Reset Varaibles
        self._n = 1
        
        
    def validate(self):
        """Takes the same arguments as :meth:`estimate`, but ensures that they are valid first."""
        if self.aperture.shape != self.phase.shape[1:]:
            raise ValueError("Phase {0!s} and Aperture {0!s} must have the same shape.".format(
                self.phase.shape[1:], self.aperture.shape
            ))
            
    
    def estimate(self):
        """Perform the estimation of the wind direction.
        """
        current = self._phase[self._ns].astype(np.float)
        ap_every = self.aperture.pupil
        ap_inner = self.aperture.edgemask
        
        convolve = self._convolve
        inv = self._inv
        
        idl = self.idl
        iterations = self.iterations
        
        nparray = np.array
        npsum = np.sum
        npdot = np.dot
        npfloat = np.float
        
        mode = self.shift.mode
        order = self.shift.order
        shift = self.shift.func
        
        GradI = self._GradI
        DeltaI = self._DeltaI
        
        wind = self._wind
        
        # Variables that are established before the iterations begin
        kernel = np.array([[ -0.5, 0.0, 0.5 ]])
        kernelT = kernel.T
        denominator = np.zeros((2,2))
        
        
        for n in self.looper(range(self._ns+1,self._nt)):
            # Normalize inputs and place them in the local namespace.
            previous = current
            current = self._phase[n].astype(npfloat)
            
            # Create the Gradient Matrix (X,Y)
            gcurr = depiston(current,ap_every)
            GradI[0,:,:] = convolve(gcurr,kernel,mode='same') * ap_every * -1.0
            GradI[1,:,:] = convolve(gcurr,kernelT,mode='same') * ap_every * -1.0
            
            if idl:
                # Aparently scipy.convolve returns values along the edges where IDL convol doesn't.
                #TODO: Examine when and where this is true!
                GradI[0,...,0] = 0.0
                GradI[0,...,-1] = 0.0
                GradI[1,0,...] = 0.0
                GradI[1,-1,...] = 0.0
            else:
                GradI[0,...] *= ap_inner
                GradI[1,...] *= ap_inner
                
            denominator[0,0] = npsum(GradI[0,...]*GradI[0,...])
            denominator[0,1] = npsum(GradI[0,...]*GradI[1,...])
            denominator[1,0] = npsum(GradI[1,...]*GradI[0,...])
            denominator[1,1] = npsum(GradI[1,...]*GradI[1,...])
            
            # Setup a reference wavefront
            ref = depiston(current * ap_inner, ap_inner)
            
            for k in range(iterations):
                DeltaI = ref - depiston(shift(
                    input = previous,
                    shift = wind[0,::-1],
                    mode = mode,
                    order = order,
                ) * ap_inner, ap_inner)
                numerator = nparray([[npsum(GradI[0,...]*DeltaI)],[npsum(GradI[1,...]*DeltaI)]])
                
                d_wind = npdot(-inv(denominator),numerator)
                
                wind[0] += d_wind[:,0]
                
            # Final Step
            self._winds[n] = wind
        
        
    


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
    
    This is an almost direct port of ``estimate_wind_gn.pro`` from Luke Johnson
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
            order = 1 if linear else 3,
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