# -*- coding: utf-8 -*-
# 
#  fmts.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-14.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np

from aopy.util.math import depiston
from aopy.aperture import Aperture
from .core import BaseEstimator
from aopy.util.basic import ConsoleContext


from pyshell.core import Struct

class FourierModeEstimator(BaseEstimator):
    """Estimates wind using the Fourier Mode Timeseries Method"""
    def __init__(self):
        super(FourierModeEstimator, self).__init__()
        
    
    def setup(self,case):
        """docstring for setup"""
        self.case = case
        self.config = self.case.config
        self.rate = self.case.rate
        
        self._fmode = self.case.telemetry.fmode
        if hasattr(self.case.telemetry,'_fmode_dmtransfer'):
            self._fmode_dmtransfer = self.case.telemetry._fmode_dmtransfer
        else:
            self._fmode_dmtransfer = np.ones_like(self._fmode[0])
        return self
    
    
    def _periodogram(self):
        """Create a periodogram from a set of fourier modes."""
        total_length = self.case.telemetry.nt
        per_length = 2048
        psd_shape = tuple((per_length,)+self._fmode.shape[1:])
        
        if self.config.get("prefilter.mean_remove",True):
            self._fmode -= np.mean(self._fmode,axis=0)
        
        if self.config.get("periodogram.half_overlap",True):
           num_intervals = np.floor(total_length/(per_length/2)) - 1
           start_indices = np.arange(num_intervals)*per_length/2
        else:
           num_intervals = np.floor(total_length/(per_length)) 
           start_indices = np.arange(num_intervals)*per_length
        
        ind = np.arange(per_length,dtype=np.float)
        window = 0.42 - 0.5*np.cos(2.0*np.pi*ind/(per_length-1)) + 0.08*np.cos(4.0*np.pi*ind/(per_length-1))
        window = np.tile(window[:,np.newaxis,np.newaxis],(1,)+psd_shape[1:])
        import scipy.fftpack
        psd = np.zeros(psd_shape,dtype=np.complex)
        for a in start_indices:
            psd += np.power(np.abs(scipy.fftpack.fft(self._fmode[a:a+per_length]*window,axis=0)),2.0)
        psd /= num_intervals
        psd /= np.sum(window**2.0,axis=0)
        psd /= per_length
        psd *= self._fmode_dmtransfer[:psd_shape[1],:psd_shape[2]]
        self.hz = np.mgrid[-1*per_length/2:per_length/2] / per_length * self.case.rate
        self.psd = psd
        
    def _periodogram_to_phase(self):
        """docstring for _periodogram_to_phase"""
        import scipy.fftpack
        s = 1j*2.0*np.pi*scipy.fftpack.fftshift(self.hz)
        bigT = 1.0/self.rate
        wfs_cont = (1.0 - np.exp(-bigT*s))/(bigT*s)
        wfs_cont[0] = 1.0
        dm_cont = wfs_cont
        delay_cont = np.exp(-1.0*self.config["system.tau"]*s)
        zinv = np.exp(-1.0*bigT*s)
        cofz = self.config["system.gain"]/(1.0 - self.config["system.integrator_c"]*zinv)
        delay_term = wfs_cont*dm_cont*delay_cont
        tf_to_convert_to_phase = np.abs((1 + delay_term*cofz)/(cofz))**2.0
        self.psd *= np.tile(tf_to_convert_to_phase[:,np.newaxis,np.newaxis],(1,)+self.psd.shape[1:])
    
    def _split_atmosphere_and_noise(self):
        """Split PSDs into atmosphere and noise terms."""
        per_length = self.psd.shape[2]
        wid = per_length/8.0
        ca = per_length/2 + wid
        cb = per_length/2 - wid
        noise_psds = np.median(self.psd[ca:cb,...],axis=0)
        noise_stds = np.std(self.psd[ca:cb,...],axis=0)
        mask = self.psd <= (noise_psds + 2.0*noise_stds)
        print("Masking %d noisy positions from PSDs" % np.sum(mask))
        self.psd[mask] = 0.0
    
    @property
    def omega(self):
        """docstring for omega"""
        return self.hz / self.rate * 2 * np.pi
        
    def estimate(self):
        """docstring for estimate"""
        self._periodogram()
        self._periodogram_to_phase()
        self._split_atmosphere_and_noise()
        
    def finish(self):
        """docstring for finish"""
        pass
        
        
class Periodogram(ConsoleContext):
    """PowerSpectralDistributions"""
    def __init__(self, psds,hz):
        super(Periodogram, self).__init__()
        self.psds = psds
        self.hz = hz
        
    def show_psd(self,ax,k,l,maxhz=50):
        """docstring for show_psd"""
        import scipy.fftpack
        
        psd = scipy.fftpack.fftshift(self.psds[:,k,l])
        
        ax.set_title("Periodogram for $k={k:d}$ and $l={l:d}$".format(k=k,l=l))
        ax.set_xlabel("Frequency (Hz)")
        ax.set_ylabel("Power")
        ax.semilogy(self.hz,np.real(psd))
        ax.set_xlim(-1*maxhz,maxhz)
        ax.grid(True)
        
        
        
        
    
        