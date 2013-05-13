# -*- coding: utf-8 -*-
# 
#  core.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-01.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import abc
import os, os.path
import warnings

import numpy as np

from astropy.io import fits

import pyshell
from pyshell.config import StructuredConfiguration, DottedConfiguration

from aopy.aperture import Aperture
from aopy.util.basic import ConsoleContext

class WCAOCase(ConsoleContext):
    """A representation of a specific WCAO data case."""
    
    __metaclass__ = abc.ABCMeta
    
    def __init__(self, instrument, casename, configuration):
        super(WCAOCase, self).__init__()
        self._config = StructuredConfiguration.make(configuration)
        self._config.dn = StructuredConfiguration
        self.instrument = instrument
        self.casename = casename
        self.results = {}
        self.telemetry = WCAOTelemetry(self)
        
    @property
    def name(self):
        """Return the full name"""
        return "{0.instrument:s}-{0.casename:s}".format(self)
        
    @property
    def config(self):
        """Instrument specific configuration"""
        return self._config[self.instrument]
        
    @property
    def rate(self):
        """AO system control rate"""
        return self.config["system.rate"]
    
    @property
    def subapd(self):
        """Subaperture Diameter"""
        return self.config["system.d"]
    
    @property
    def data_format(self):
        """Data format specifier"""
        return self.config["data.format"]
    
    def addresult(self,data,klass,dtype):
        """Add a result"""
        self.results[dtype] = klass(self,data,dtype)
    
        
class WCAOTelemetry(ConsoleContext):
    """The sub-representation of a set of telemetry for a specific WCAOCase."""
    def __init__(self, case):
        super(WCAOTelemetry, self).__init__()
        self.case = case
        self.config = self.case.config
        self.aperture = None
        self._nt = None
        self._phase = None
        self.phase_path = self.filepath("proc","phase","fits")
        self._fmode = None
        self.fmode_path = self.filepath("proc","fmode","fits")
        self.raw_path = os.path.expanduser(os.path.join(self.config["data.root"],self.config["data.cases.{0.casename:s}.raw_data".format(self.case)]))
        
    @property
    def phase(self):
        """A phase property that properly falls through to loading functions."""
        if self._phase is None and os.path.exists(self.phase_path):
            self.load_phase()
        elif self._phase is None and os.path.exists(self.raw_path):
            self.load_raw()
        elif self._phase is None:
            raise ValueError("{0}:Cannot Load Phase".format(self))
        return self._phase
        
    @property
    def fmode(self):
        """A phase property that properly falls through to loading functions."""
        if self._fmode is None and os.path.exists(self.fmode_path):
            self.load_fmode()
        elif self._fmode is None and os.path.exists(self.raw_path):
            self.load_raw()
        elif self._fmode is None:
            raise ValueError("{0}:Cannot Load Fourier Modes".format(self))
        return self._fmode
        
    @property
    def nt(self):
        """Number of timesteps"""
        return self._nt
        
    def filename(self,prepend="data",ext="fits"):
        """docstring for filename"""
        return "{prepend}_{config}.{ext}".format(
            prepend=prepend,
            config=self.config.hash[:8],
            ext=ext,
        )
    
    def filepath(self,kind,prepend="data",ext="fits"):
        """Make a filepath"""
        return os.path.expanduser(os.path.join(self.config["data.root"],"data",self.case.instrument,kind,self.filename(prepend,ext)))
        
        
    def _load_trs(self):
        """docstring for _load_trs"""
        with warnings.catch_warnings(record=True) as wlist:
            from scipy.io import readsav
            scope = readsav(self.raw_path)
        return scope['trsdata']['residualwavefront'][0]
        
    def _remap_disp2d(self,rawdata):
        """Use the Keck disp2d re-mapper"""
        from .keck import disp2d
        import scipy.fftpack
        self.aperture = Aperture(disp2d(np.ones(rawdata.shape[1])))
        self._nt = rawdata.shape[0]
        self._phase = np.zeros((self._nt,)+self.aperture.shape,dtype=np.float)
        self._fmode = np.zeros((self._nt,)+self.aperture.shape,dtype=np.complex)
        for t in self.range(self._nt):
            self._phase[t,...] = disp2d(rawdata[t,:])
            self._fmode[t,...] = scipy.fftpack.fft2(self._phase[t,...])
        
    def load_raw(self):
        """Load raw data from files."""
        rawdata = getattr(self,'_load_'+self.config["data.cases.{0.casename:s}.raw_format".format(self.case)])()
        getattr(self,'_remap_'+self.config["data.cases.{0.casename:s}.raw_remap".format(self.case)])(rawdata)
    
    def load_phase(self):
        """Load phase data from files."""
        with fits.open(self.phase_path) as ffile:
            self._phase = ffile[0].data
        self._nt = self._phase.shape[0]
        if self.aperture is None:
            self.aperture = Aperture((self._phase[0] != 0))
    
    def save_phase(self):
        """Save phase data to files"""
        HDU = fits.PrimaryHDU(self._phase)
        HDU.writeto(self.phase_path)
    
    def load_fmode(self):
        """Load fourier-mode data from files"""
        with fits.open(self.fmode_path) as ffile:
            self._fmode = ffile[0].data[0,...] + 1j * ffile[0].data[1,...]
        self._nt = self._fmode.shape[0]
        if self.aperture is None:
            import numpy.fft
            self.aperture = Aperture(numpy.fft.ifft2(self._fmode[0,...]) != 0)
    
    def save_fmode(self):
        """Save fourier mode data to files."""
        fmodeout = np.array([np.real(self._fmode),np.imag(self._fmode)])
        HDU = fits.PrimaryHDU(fmodeout)
        HDU.writeto(self.fmode_path)
        
