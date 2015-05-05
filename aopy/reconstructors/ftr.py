# -*- coding: utf-8 -*-
"""
:mod:`ftr` – The Fourier Transfomr reconstructor
================================================

The fourier transform reconstructor converts slopes (x and y slope grids) to
phase values. The reconstruction works using the fourier transform of the x
and y slopes, and applying a filter, which accounts for the way in which those
slopes map to phase.

The concept for the reconstructor, and the filters documented here, are taken
from Lisa Poyneer's 2007 dissertaiton.

"""

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

# Python Imports
import abc
import six
import collections

# Scientific Python Imports
import numpy as np
import scipy.fftpack
from astropy.utils import lazyproperty

# Local imports
from ..util.math import complexmp, ignoredivide

FTRFilter = collections.namedtuple("FTRFilter", ["gx", "gy", "name"])

@six.add_metaclass(abc.ABCMeta)
class FourierTransformReconstructor(object):
    """Fourier Transform Reconstruction Base
    """
    
    _gx = None
    _gy = None
    _n = 0
    _dzero = None
    _filtername = "UNDEFINED"
    
    def __repr__(self):
        """Represent this object."""
        return "<{0} ({1:d}x{2:d}) filter='{3}'>".format(self.__class__.__name__, self.n, self.n, self.name)
    
    def __init__(self, n, filter=None):
        super(FourierTransformReconstructor, self).__init__()
        self._n = n
        self._filtername = "Unknown"
        if filter is not None:
            self.use(filter)
        
    @property
    def name(self):
        """Filter name"""
        return self._filtername
        
    @name.setter
    def name(self, value):
        """Set the filter name."""
        self.use(value)
        
    @property
    def filter(self):
        """The filter components."""
        return FTRFilter(self.gx, self.gy, self.name)
        
    @property
    def n(self):
        """The dimension size. Reconstructs on an (n x n) grid."""
        return self._n
        
    @property
    def shape(self):
        """Shape of the reconstructed grid."""
        return (self.n, self.n)
        
    @property
    def gx(self):
        """The x filter"""
        return self._gx
        
    @gx.setter
    def gx(self, gx):
        """Set the x filter"""
        self._gx = self._validate_filter(gx)
        self._denominator = None
        self._filtername = "Unknown"
        
    @property
    def gy(self):
        """The y filter"""
        return self._gy
        
    @gy.setter
    def gy(self, gy):
        """Set and validate the y filter"""
        self._gy = self._validate_filter(gy)
        self._denominator = None
        self._filtername = "Unknown"
        
        
    def _validate_filter(self, _filter):
        """Ensure that a filter is the correct shape.
        
        This method checks the shape and that the filter is all finite.
        
        :param _filter: The filter array to check.
        :returns: The filter, correctly typed and checked for consistency.
        """
        gf = np.asarray(_filter).astype(np.complex)
        if gf.shape != (self.n, self.n):
            raise ValueError("Filter should be same shape as input data. Found {0}, expected {1}.".format(gf.shape, (self.n, self.n)))
        if not np.isfinite(gf).all():
            raise ValueError("Filter must be finite at all points!")
        return gf
        
    @property
    def denominator(self):
        """Filter denominator"""
        if self._denominator is not None:
            return self._denominator
        self._denominator = np.abs(self.gx)**2.0 + np.abs(self.gy)**2.0
        self._denominator[(self._denominator == 0.0)] = 1.0 #Fix non-hermetian parts.
        return self._denominator
        
    def apply_filter(self, xs_ft, ys_ft):
        """Apply the filter to the FFT'd values.
        
        :param xs_ft: The x fourier transform
        :param ys_ft: THe y fourier transform
        :returns: The filtered estimate, fourier transformed.
        
        """
        return (xs_ft * np.conj(self.gx) + ys_ft * np.conj(self.gy))/self.denominator
        
    def reconstruct(self, xs, ys, axes=(0,1)):
        """The reconstruction method"""
        
        xs_ft = scipy.fftpack.fftn(xs, axes=axes)
        ys_ft = scipy.fftpack.fftn(ys, axes=axes)
        
        est_ft = self.apply_filter(xs_ft, ys_ft)
        
        estimate = np.real(scipy.fftpack.ifftn(est_ft, axes=axes))
        
        return estimate
        
    def __call__(self, xs, ys, axes=(0,1)):
        """Reconstruct the phase.
        
        :param xs: The x slopes.
        :param ys: The y slopes.
        
        """
        return self.reconstruct(xs, ys, axes=axes)
        
    _REGISTRY = {}
        
    @classmethod
    def register(cls, name, filter=None):
        """Register a filter generating function."""
        
        def _register(filterfunc):
            """Filter Function"""
            cls._REGISTRY[name] = filterfunc
            return filterfunc
        
        if six.callable(name):
            filterfunc = name
            cls._REGISTRY[filterfunc.__name__] = filterfunc
            return filterfunc
        elif isinstance(name, six.text_type) and filter is None:
            return _register
        elif isinstance(name, six.text_type) and six.callable(filter):
            return _register(filterfunc)
        else:
            raise TypeError("Filter must be a callable, or a name, and used as a decorator.")
    
    def use(self, filter):
        """Use a particular filter."""
        self.gx, self.gy, name = self._REGISTRY[filter](self.n)
        self._filtername = name
        
        

@FourierTransformReconstructor.register("mod_hud")
def mod_hud_filter(n):
    """The modified hudgins filter is a geomoetry similar to
    a Fried geometry, but where the slope measurements, rather than
    being the difference between two adjacent points, the slope is
    taken to be the real slope at the point in the center of four
    phase measurement points."""
    import scipy.fftpack
    ff = scipy.fftpack.fftfreq(n, 1/(2*np.pi))
    fx, fy = np.meshgrid(ff, ff)

    gx = np.exp(1j*fy/2)*(np.exp(1j*fx) - 1)
    gy = np.exp(1j*fx/2)*(np.exp(1j*fy) - 1)

    gx[n/2,:] = 0.0
    gy[:,n/2] = 0.0
    
    return FTRFilter(gx, gy, "mod_hud")

@FourierTransformReconstructor.register("fried")
def fried_filter(n):
    """The fried filter is for a system geometry where the
    slope measruement points are taken to be the difference
    between two adjacent points. As such, the slopes are
    reconstructed to be the phase points 1/2 a subaperture
    away from the measured point.

    In this scheme, the slope measruement in the center of 
    four phase measurement points is taken (in the x-direction)
    to be the average of the x slope between the top measruements
    and the x slope between the bottom measurement."""
    ff = scipy.fftpack.fftfreq(n, 1/(2*np.pi))
    fx, fy = np.meshgrid(ff, ff)
    
    gx = (np.exp(1j*fy/2) + 1)*(np.exp(1j*fx) - 1)
    gy = (np.exp(1j*fx/2) + 1)*(np.exp(1j*fy) - 1)
    
    gx[n/2,:] = 0.0
    gy[:,n/2] = 0.0
    
    return FTRFilter(gx, gy, "fried")

@FourierTransformReconstructor.register("ideal")
def ideal_filter(n):
    """An Ideal filter represents a phase where the slope
    measurements are taken to be a continuous sampling of
    the phase between phase measurement points. """
    ff = scipy.fftpack.fftfreq(n, 1/(2*np.pi))
    fx, fy = np.meshgrid(ff, ff)
    
    with ignoredivide():
        gx = np.conj(1/fy * ((np.cos(fy) - 1) * np.sin(fx) + (np.cos(fx) - 1) * np.sin(fy) ) +
                  1j/fy * ((np.cos(fx) - 1) * (np.cos(fy) - 1) - np.sin(fx) * np.sin(fy)))
        gy = np.conj(1/fx * ((np.cos(fx) - 1) * np.sin(fy) + (np.cos(fy) - 1) * np.sin(fx)) +
                  1j/fx * ((np.cos(fy) - 1) * (np.cos(fx) - 1) - np.sin(fy) * np.sin(fx)))
      
    # Exclude division by zero!
    gx[0,:] = 0
    gy[:,0] = 0
    
    # the filter is anti-Hermitian here. The real_part takes care
    # of it, but simpler to just zero it out.
    gx[n/2,:] = 0.0
    gy[:,n/2] = 0.0
    
    return FTRFilter(gx, gy, "ideal")
    