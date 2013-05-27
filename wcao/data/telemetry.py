# -*- coding: utf-8 -*-
# 
#  telemetry.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-13.
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
from aopy.util.math import circle

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
        self.fmode_path = self.filepath("proc","fmodes","fits")
        self.raw_path = os.path.expanduser(os.path.join(self.config["data.root"],self.config["data.cases.{0.casename:s}.raw_data".format(self.case)]))
        self.data_config = self.config["data.cases.{0.casename:s}".format(self.case)]
        
        
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
        return "{casename}_{prepend}.{ext}".format(
            casename= self.case.casename,
            prepend=prepend,
            config=self.config.hash[:8],
            ext=ext,
        )
    
    def filepath(self,kind,prepend="data",ext="fits"):
        """Make a filepath"""
        return os.path.expanduser(os.path.join(self.config["data.root"],"data",self.case.instrument,kind,self.filename(prepend,ext)))
        
    def _load_simulated(self):
        """Generate simulated data"""
        from aopy.atmosphere.wind import ManyLayerScreen
        self.aperture = Aperture(circle(self.config["system.n"]//2.0,self.config["system.n"]//2.0))
        wind = np.array(self.data_config["wind"],dtype=np.float)
        wind /= self.config["system.d"]
        wind /= self.config["system.rate"]
        Screen = ManyLayerScreen(self.aperture.shape,
            self.data_config["r0"],du=self.config["system.d"],
            vel=wind,tmax=self.data_config["raw_time"]).setup()
        return Screen
        
    def _load_trs(self):
        """docstring for _load_trs"""
        with warnings.catch_warnings(record=True) as wlist:
            from scipy.io import readsav
            scope = readsav(self.raw_path)
        return scope['trsdata']['residualwavefront'][0]
        
    def _remap_3d_screen(self,rawdata):
        """Basically, a null-remap"""
        import scipy.fftpack
        self._nt = self.data_config["ntime"]
        self._phase = np.zeros((self._nt,)+self.aperture.shape)
        self._fmode = np.zeros((self._nt,)+self.aperture.shape,dtype=np.complex)
        for t in self.looper(range(self._nt)):
            self._phase[t,...] = rawdata.get_screen(t)
            self._fmode[t,...] = scipy.fftpack.fft2(self._phase[t,...])
        
    def _remap_disp2d(self,rawdata):
        """Use the Keck disp2d re-mapper"""
        from .keck import disp2d,transfac
        import scipy.fftpack
        self.aperture = Aperture(disp2d(np.ones(rawdata.shape[1])))
        self._nt = rawdata.shape[0]
        self._phase = np.zeros((self._nt,)+self.aperture.shape,dtype=np.float)
        self._fmode = np.zeros((self._nt,)+self.aperture.shape,dtype=np.complex)
        for t in self.looper(range(self._nt)):
            self._phase[t,...] = disp2d(rawdata[t,:])
            self._fmode[t,...] = scipy.fftpack.fft2(self._phase[t,...])
            
    def _trans_disp2d(self):
        """docstring for _trans_keck"""
        self._fmode_dmtransfer = transfac()
        
    def _trans_ones(self):
        """docstring for _trans_ones"""
        self._fmode_dmtransfer = np.ones(self._fmode.shape[1:])
        
    def load_raw(self):
        """Load raw data from files."""
        rawdata = getattr(self,'_load_'+self.config["data.cases.{0.casename:s}.raw_format".format(self.case)])()
        getattr(self,'_remap_'+self.config["data.cases.{0.casename:s}.raw_remap".format(self.case)])(rawdata)
        getattr(self,'_trans_'+self.config.get("data.cases.{0.casename:s}.raw_remap".format(self.case),"ones"))
    
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
        HDU.header["CONFIG"] = self.config.hash
        HDU.writeto(self.phase_path,clobber=True)
    
    def load_fmode(self):
        """Load fourier-mode data from files"""
        with fits.open(self.fmode_path) as ffile:
            self._fmode = ffile[0].data[0,...] + 1j * ffile[0].data[1,...]
        self._nt = self._fmode.shape[0]
        if self.aperture is None:
            import scipy.fftpack
            self.aperture = Aperture(scipy.fftpack.ifft2(self._fmode[0,...]) != 0)
        getattr(self,'_trans_'+self.config.get("data.cases.{0.casename:s}.raw_remap".format(self.case),"ones"))
        
    
    def save_fmode(self):
        """Save fourier mode data to files."""
        fmodeout = np.array([np.real(self._fmode),np.imag(self._fmode)])
        HDU = fits.PrimaryHDU(fmodeout)
        HDU.header["CONFIG"] = self.config.hash
        HDU.writeto(self.fmode_path,clobber=True)
        
