# -*- coding: utf-8 -*-
# 
#  ftr.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-08-12.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

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

# Scientific Python Imports
import numpy as np
import scipy.fftpack
from astropy.utils.misc import lazyproperty

# Local imports
from ..util.math import complexmp, ignoredivide
from ..util.basic import resolve

class FourierTransformReconstructor(object):
    """Fourier Transform Reconstruction Base
    """
    
    _gx = None
    _gy = None
    _n = None
    _dzero = None
    
    __metaclass__ = abc.ABCMeta
    
    def __init__(self, n):
        super(FourierTransformReconstructor, self).__init__()
        self._n = n
        
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
        
    @property
    def gy(self):
        """The y filter"""
        return self._gy
        
    @gy.setter
    def gy(self, gy):
        """Set and validate the y filter"""
        self._gy = self._validate_filter(gy)
        self._denominator = None
        
    def _validate_filter(self, _filter):
        """Ensure that a filter is the correct shape.
        
        This method checks the shape and that the filter is all finite.
        
        :param _filter: The filter array to check.
        :returns: The filter, correctly typed and checked for consistency.
        """
        gf = np.asarray(_filter).astype(np.complex)
        if gf.shape != (self.n, self.n):
            raise ValueError("Filter should be same shape as input data. Found {}, expected {}.".format(gf.shape, (self.n, self.n)))
        if not np.isfinite(gf).all():
            raise ValueError("Filter must be finite at all points!")
        return gf
        
    @property
    def denominator(self):
        """Filter denominator"""
        if self._denominator is not None:
            return self._denominator
        denominator = np.abs(self.gx)**2.0 + np.abs(self.gy)**2.0
        denominator[(denominator == 0.0)] = 1.0
        self._denominator = denominator
        return denominator
        
    def filter(self, xs_ft, ys_ft):
        """Apply the filter to the FFT'd values.
        
        :param xs_ft: The x fourier transform
        :param ys_ft: THe y fourier transform
        :returns: The filtered estimate, fourier transformed.
        
        """
        return (np.conj(self.gx) * xs_ft + np.conj(self.gy) * ys_ft)/self.denominator
        
    def reconstruct(self, xs, ys):
        """The reconstruction method"""
        
        xs_ft = scipy.fftpack.fftn(xs)
        ys_ft = scipy.fftpack.fftn(ys)
        
        est_ft = self.filter(xs_ft, ys_ft)
        
        estimate = np.real(scipy.fftpack.ifftn(est_ft))
        
        return estimate
        
    def __call__(self, xs, ys):
        """Reconstruct the phase.
        
        :param xs: The x slopes.
        :param ys: The y slopes.
        
        """
        return self.reconstruct(xs, ys)
        
        
class FixedFilterFTR(FourierTransformReconstructor):
    """A fixed filter version of the fourier reconstructor. The FTR filter is set once, and then left."""
    def __init__(self, n, filtername=None):
        super(FixedFilterFTR, self).__init__(n=n)
        
        if filtername is not None:
            self.set_filter(filtername)
        
    @property
    def filtername(self):
        """The filter name"""
        return self._filtername
        
    def set_filter(self, filtername):
        """Set the filter name, and apply it."""
        filter_function_name = "use_{filter}_filter".format(filter=filtername.replace(" ","_"))
        if hasattr(self, filter_function_name):
            getattr(self, filter_function_name)()
            self._filtername = filtername
        else:
            try:
                gx, gy = resolve(filtername)(n=self.n)
                self.gx, self.gy = gx, gy
            except ImportError:
                raise KeyError("{}: Filter {filter} could not be found.".format(self, filtername))
            else:
                self._filtername = filtername
        
    def use_mod_hud_filter(self):
        """The modified hudgins filter is a geomoetry similar to
        a Fried geometry, but where the slope measurements, rather than
        being the difference between two adjacent points, the slope is
        taken to be the real slope at the point in the center of four
        phase measurement points."""
        import scipy.fftpack
        ff = scipy.fftpack.fftfreq(self.n, 1/(2*np.pi))
        fx, fy = np.meshgrid(ff, ff)
        
        gx = np.exp(1j*fy/2)*(np.exp(1j*fx) - 1)
        gy = np.exp(1j*fx/2)*(np.exp(1j*fy) - 1)
        
        gx[self.n/2,:] = 0.0
        gy[:,self.n/2] = 0.0
        
        self.gx = gx
        self.gy = gy
        
    def use_fried_filter(self):
        """The fried filter is for a system geometry where the
        slope measruement points are taken to be the difference
        between two adjacent points. As such, the slopes are
        reconstructed to be the phase points 1/2 a subaperture
        away from the measured point.
        
        In this scheme, the slope measruement in the center of 
        four phase measurement points is taken (in the x-direction)
        to be the average of the x slope between the top measruements
        and the x slope between the bottom measurement."""
        ff = scipy.fftpack.fftfreq(self.n, 1/(2*np.pi))
        fx, fy = np.meshgrid(ff, ff)
        
        gx = (np.exp(1j*fy/2) + 1)*(np.exp(1j*fx) - 1)
        gy = (np.exp(1j*fx/2) + 1)*(np.exp(1j*fy) - 1)
        
        gx[self.n/2,:] = 0.0
        gy[:,self.n/2] = 0.0
        
        self.gx = gx
        self.gy = gy
    
    def use_no_filter(self):
        """Don't apply a filter"""
        ff = scipy.fftpack.fftfreq(self.n, 1/(2*np.pi))
        fx, fy = np.meshgrid(ff, ff)
        
        gx = 1j*np.ones_like(fx)
        gy = 1j*np.ones_like(fy)
        
        gx[self.n/2,:] = 0.0
        gy[:,self.n/2] = 0.0
        
        self.gx = gx
        self.gy = gy
        
    
    def use_ideal_filter(self):
        """An Ideal filter represents a phase where the slope
        measurements are taken to be a continuous sampling of
        the phase between phase measurement points. """
        ff = scipy.fftpack.fftfreq(self.n, 1/(2*np.pi))
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
        gx[self.n/2,:] = 0.0
        gy[:,self.n/2] = 0.0
        
        self.gx = gx
        self.gy = gy
        
        
