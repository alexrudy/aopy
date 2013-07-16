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
        self.raw_path = os.path.expanduser(os.path.join(self.case.inst_config["data.root"],self.case.inst_config["data.cases.{0.casename:s}.raw_data".format(self.case)]))
        self.data_config = self.case.inst_config["data.cases.{0.casename:s}".format(self.case)]
        self.log = pyshell.getLogger(__name__)
        
    def __str__(self):
        """Single line string representation"""
        return "{self.case.casename:12.12s}: {shape:>9.9s} x {ntime:<7.0g} = {time:3.1f}s at {rate:5.0g}Hz".format(
            self = self,
            shape = self.aperture.__shape_str__(),
            ntime = self.nt,
            time = self.nt / self.case.rate,
            rate = self.case.rate,
        )
        
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
        """A fourier mode property that properly falls through to loading functions."""
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
        """A filename for this case"""
        return "{casename}_{prepend}.{ext}".format(
            casename= self.case.casename,
            prepend=prepend,
            config=self.config.hash[:8],
            ext=ext,
        )
    
    def filepath(self,kind,prepend="data",ext="fits"):
        """Make a filepath for this case"""
        return os.path.expanduser(os.path.join(self.case.inst_config["data.root"],"data",self.case.instrument,kind,self.filename(prepend,ext)))
        
    def _load_simulated(self):
        """Generate simulated data"""
        from aopy.atmosphere.wind import ManyLayerScreen
        self.log.debug("Loading Simulated Data")
        self.aperture = Aperture(circle(self.case.inst_config["system.n"]//2.0,self.case.inst_config["system.n"]//2.0))
        wind = np.array(self.data_config["wind"],dtype=np.float)
        self.log.debug("Generated Aperture adn Wind")
        Screen = ManyLayerScreen(self.aperture.shape,
            self.data_config["r0"],du=self.case.inst_config["system.d"],
            vel=wind,tmax=self.data_config["raw_time"],delay=True)
        self.log.debug("Generating Screen of size %g %g" % Screen.shape)
        Screen.setup()
        self.log.debug("Loaded Simulated Data")        
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
        self.log.debug("Remaping Simulated Data")        
        self._nt = self.data_config["ntime"]
        self._phase = np.zeros((self._nt,)+self.aperture.shape)
        self._fmode = np.zeros((self._nt,)+self.aperture.shape,dtype=np.complex)
        for t in self.looper(range(self._nt)):
            self._phase[t,...] = rawdata.get_screen(t)
            self._fmode[t,...] = scipy.fftpack.fftshift(scipy.fftpack.fft2(self._phase[t,...]))
        self.log.debug("Remaped Simulated Data")
        
        
    def _remap_disp2d(self,rawdata):
        """Use the Keck disp2d re-mapper"""
        from .keck import disp2d
        import scipy.fftpack
        self.aperture = Aperture(disp2d(np.ones(rawdata.shape[1])))
        self._nt = rawdata.shape[0]
        self._phase = np.zeros((self._nt,)+self.aperture.shape,dtype=np.float)
        self._fmode = np.zeros((self._nt,)+self.aperture.shape,dtype=np.complex)
        for t in self.looper(range(self._nt)):
            self._phase[t,...] = disp2d(rawdata[t,:])
            self._fmode[t,...] = scipy.fftpack.fftshift(scipy.fftpack.fft2(self._phase[t,...]))
            
    def _trans_disp2d(self):
        """docstring for _trans_keck"""
        from .keck import transfac
        self._fmode_dmtransfer = transfac()
        
    def _trans_ones(self):
        """docstring for _trans_ones"""
        self._fmode_dmtransfer = np.ones(self._fmode.shape[1:])
        
    def _trans_fftshift(self):
        """docstring for _trans_fftshift"""
        import scipy.fftpack
        self._fmode = scipy.fftpack.fftshift(self._fmode,axes=(1,2))
        
    def _trans_offset(self):
        """Perform an offset transfer"""
        import scipy.fftpack
        self._fmode = scipy.fftpack.fftshift(self._fmode,axes=(1,2))
        self._fmode = np.sqrt(self._fmode[2:] * self._fmode[:-2])
        self._nt = self._nt - 2
        
    def load_raw(self):
        """Load raw data from files."""
        rawdata = getattr(self,'_load_'+self.data_config["raw_format"])()
        getattr(self,'_remap_'+self.data_config["raw_remap"])(rawdata)
        getattr(self,'_trans_'+self.data_config.get("raw_trans","ones"))
    
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
        HDU.header["CONFIG"] = (self.config.hash, "Hash for configuration")
        HDU.writeto(self.phase_path,clobber=True)
    
    def load_fmode(self):
        """Load fourier-mode data from files"""
        with fits.open(self.fmode_path) as ffile:
            self._fmode = ffile[0].data[0,...] + 1j * ffile[0].data[1,...]
        self._nt = self._fmode.shape[0]
        if self.aperture is None:
            import scipy.fftpack
            self.aperture = Aperture(scipy.fftpack.ifft2(self._fmode[0,...]) != 0)
        getattr(self,'_trans_'+self.data_config.get("raw_trans","ones"))
        
    
    def save_fmode(self):
        """Save fourier mode data to files."""
        fmodeout = np.array([np.real(self._fmode),np.imag(self._fmode)])
        HDU = fits.PrimaryHDU(fmodeout)
        HDU.header["CONFIG"] = (self.config.hash, "Hash for configuration")
        HDU.header["DATA"] = ("data[0] + 1j * data[1]", "Data remap in python")
        HDU.writeto(self.fmode_path,clobber=True)
        
