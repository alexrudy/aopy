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

"""

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

# Python Imports
import abc

# Scientific Python Imports
import numpy as np
from astropy.utils.misc import lazyproperty

# Personal Modules
import pyshell

# Local imports
from ..util.math import complexmp, ignoredivide
from ..util.basic import resolve

class FourierTransformReconstructor(object):
    """Fourier Transform Reconstruction Base"""
    
    _gx = None
    _gy = None
    _n = None
    _dzero = None
    
    __metaclass__ = abc.ABCMeta
    
    def __init__(self, n):
        super(FourierTransformReconstructor, self).__init__()
        self.log = pyshell.getLogger()
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
        if self._gx is not None:
            raise ValueError("Cannot change filter.")
        self._gx = self._validate_filter(gx)
        
    @property
    def gy(self):
        """The y filter"""
        return self._gy
        
    @gy.setter
    def gy(self, gy):
        """Set and validate the y filter"""
        if self._gy is not None:
            raise ValueError("Cannot change filter.")
        self._gy = self._validate_filter(gy)
        
    def _validate_filter(self, _filter):
        """docstring for _validate_filter"""
        gf = np.array(_filter).astype(np.complex)
        if gf.shape != (self.n, self.n):
            raise ValueError("Filter should be same shape as input data. Found {}, expected {}.".format(gf.shape, (self.n, self.n)))
        if not np.isfinite(gf).all():
            raise ValueError("Filter must be finite at all points!")
        return gf
        
    @lazyproperty
    def denominator(self):
        """Filter denominator"""
        denominator = np.abs(self.gx)**2.0 + np.abs(self.gy)**2.0
        self._dzero = (denominator == 0.0)
        denominator[self._dzero] = 1.0
        return denominator
        
    def reconstruct(self, xs, ys):
        """The reconstruction method"""
        import scipy.fftpack
        
        xs_ft = scipy.fftpack.fftn(xs)
        ys_ft = scipy.fftpack.fftn(ys)
        
        est_ft = (np.conj(self.gx) * xs_ft + np.conj(self.gy) * ys_ft)/self.denominator
        
        estimate = np.real(scipy.fftpack.ifftn(est_ft))
        
        return estimate
        
        
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
            self.log.info("Using {filter} filter.".format(filter=filtername))
        else:
            try:
                gx, gy = resolve(filtername)(n=self.n)
                self.gx, self.gy = gx, gy
            except ImportError:
                raise KeyError("{}: Filter {filter} could not be found.".format(self, filtername))
            else:
                self._filtername = filtername
        
    def use_mod_hud_filter(self):
        """Apply the modified hudgin filter."""
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
        """docstring for use_fried_filter"""
        import scipy.fftpack
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
        import scipy.fftpack
        ff = scipy.fftpack.fftfreq(self.n, 1/(2*np.pi))
        fx, fy = np.meshgrid(ff, ff)
        
        gx = 1j*np.ones_like(fx)
        gy = 1j*np.ones_like(fy)
        
        gx[self.n/2,:] = 0.0
        gy[:,self.n/2] = 0.0
        
        self.gx = gx
        self.gy = gy
        
    
    def use_ideal_filter(self):
        """Apply an Ideal Filter"""
        import scipy.fftpack
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
        
        
