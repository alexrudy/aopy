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

import warnings

import numpy as np

from aopy.util.math import depiston
from aopy.aperture import Aperture
from .core import BaseEstimator
from aopy.util.basic import ConsoleContext
from pyshell.core import Struct
from pyshell.config import DottedConfiguration
from pyshell import getLogger

def periodogram(data, periodogram_length, window=None, half_overlap=True):
    """Make a periodogram."""
    import scipy.fftpack
    total_length = data.shape[0]
    psd_shape = tuple((periodogram_length,)+data.shape[1:])
    
    if half_overlap:
       num_intervals = np.floor(total_length/(periodogram_length/2)) - 1
       start_indices = np.arange(num_intervals)*periodogram_length/2
    else:
       num_intervals = np.floor(total_length/(periodogram_length)) 
       start_indices = np.arange(num_intervals)*periodogram_length
    
    if window is None:
        ind = np.arange(periodogram_length,dtype=np.float)
        window = 0.42 - 0.5*np.cos(2.0*np.pi*ind/(periodogram_length-1)) + 0.08*np.cos(4.0*np.pi*ind/(periodogram_length-1))
        for i in range(len(psd_shape)-1):
            window = window[...,np.newaxis]
    
    psd = np.zeros(psd_shape,dtype=np.complex)
    for a in start_indices:
        psd += np.power(np.abs(scipy.fftpack.fft(data[a:a+periodogram_length]*window,axis=0)),2.0)
    psd /= num_intervals
    psd /= np.sum(window**2.0,axis=0)
    psd /= periodogram_length
    return psd
    
def find_and_fit_peak(psd,mask,template,omega,
    search_radius=1,mask_radius=1,float_peak=False,
    ialpha=0.99,min_alpha=0,max_alpha=1,**kwargs):
    """Find and fit a single peak"""
    import scipy.signal
    from aopy.util.curvefit import curvefit
    
    log = getLogger(__name__ + ".find_and_fit_peak")
    psd[psd < 0] = 0.0
    psd[mask] = 0.0
    correl = scipy.signal.fftconvolve(template,psd,mode='same')
    max_i = np.argmax(correl)
    max_v = np.max(correl)
    success = None
    #TODO: Sub-pixel matching for the peak!
    est_omega = max_i * (omega[0]-omega[1])
    layer = {}
    fit_psd = np.empty_like(psd)
    log.debug("Estimated Peak Value at %.3f", est_omega)
    
    p0 = np.array([ialpha,1.0],dtype=np.float)
    
    weights = (np.abs(omega - est_omega) <= search_radius).astype(np.int)
    if not weights.any():
        success = False
        log.debug("No points left in fit. Ending.")
    else:
        log.debug("Weights: %d / %d" % (np.sum(weights),weights.size))
        
    if float_peak:
        p0 = np.array([ialpha,1.0,np.real(est_omega)])
        popt, pcov, infodict, errmsg, ier = curvefit(fitter,omega,np.real(psd),p0,
            sigma=weights,full_output=True)
        est_omega = popt[2]
    else:
        popt, pcov, infodict, errmsg, ier = curvefit(fitter,omega,np.real(psd),p0,
            sigma=weights,args=(np.real(est_omega),),full_output=True)
    
    if popt[1] < 0:
        log.warning("Peak Power is negative! %g",popt[1])
        success = False
    elif popt[0] < min_alpha or popt[0] > max_alpha:
        log.warning("Alpha out of range! %.3f",popt[0])
        success = False
    else:
        success = True
        log.info("Found a peak at alpha=%f omega=%f, power=%f",popt[0],est_omega,popt[1])
        fit_psd = fitter(omega,popt[0],popt[1],est_omega)
        layer["alpha"] = popt[0]
        layer["omega"] = est_omega
        layer["variance"] = popt[1]
        layer["rms"] = np.sqrt(np.sum(fit_psd))
        mask = (mask | (np.abs(omega - est_omega) > mask_radius))
    
    log.debug("{}:{}".format(ier,errmsg))
    
    return success, layer, mask, fit_psd
    
    
def fitter(x,alpha,peak,center):
    """docstring for fitter"""
    f = peak/(1 - 2*alpha*np.cos(x-center) + alpha**2.0)
    return f

class FourierModeEstimator(BaseEstimator):
    """Estimates wind using the Fourier Mode Timeseries Method"""
    def __init__(self,config=(__name__,"fmts.yml")):
        super(FourierModeEstimator, self).__init__()
        self.config = DottedConfiguration.make(config)
    
    def setup(self,case):
        """docstring for setup"""
        self.case = case
        self.rate = self.case.rate
        self.config.merge(self.case.config)
        
        self._fmode = self.case.telemetry.fmode
        if hasattr(self.case.telemetry,'_fmode_dmtransfer'):
            self._fmode_dmtransfer = self.case.telemetry._fmode_dmtransfer
        else:
            self._fmode_dmtransfer = np.ones_like(self._fmode[0])
        return self
    
    
    def _periodogram(self):
        """Create a periodogram from a set of fourier modes."""
        import scipy.fftpack
        total_length = self.case.telemetry.nt
        per_length = self.config.get("periodogram.length",2048)
        if self.config.get("periodogram.mean_remove",True):
            self._fmode -= np.mean(self._fmode,axis=0)
        psd = periodogram(self._fmode,per_length,half_overlap=self.config.get("periodogram.half_overlap",True))
        psd *= self._fmode_dmtransfer[:psd.shape[1],:psd.shape[2]]
        self.hz = np.mgrid[-1*per_length/2:per_length/2] / per_length * self.case.rate
        self.psd = scipy.fftpack.fftshift(psd,axes=0)
        
    def _periodogram_to_phase(self):
        """docstring for _periodogram_to_phase"""
        import scipy.fftpack
        s = 1j*2.0*np.pi*scipy.fftpack.fftshift(self.hz)
        bigT = 1.0/self.rate
        s[0] = 1.0
        wfs_cont = (1.0 - np.exp(-bigT*s))/(bigT*s)
        s[0] = 0.0
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
        with warnings.catch_warnings():
            warnings.simplefilter('ignore')
            noise_stds = np.std(self.psd[ca:cb,...],axis=0)
            noise_psds[np.isnan(noise_psds)] = 0.0
        mask = self.psd <= (noise_psds + 2.0*noise_stds)
        self.log.debug("Masking %d noisy positions from PSDs" % np.sum(mask))
        self.psd[mask] = 0.0
        
    def _create_peak_template(self):
        """Make peak templates for correlation fitting"""
        import scipy.fftpack
        
        self.template = periodogram(np.zeros((self.psd.shape[0]),dtype=np.complex),self.psd.shape[0])
        self.template_ft = np.conj(scipy.fftpack.fft(self.template))
        
    def _find_and_fit_peaks(self):
        """Find and fit peaks in each PSD"""
        self.layers = np.empty(self.psd.shape[1:],dtype=object)
        if self.console:
            from astropy.utils.console import ProgressBar
            pbar = ProgressBar(self.psd.shape[1]*self.psd.shape[2])
        else:
            pbar = None
        for k in range(self.psd.shape[1]):
            for l in range(self.psd.shape[2]):
                self.layers[k,l] = self._find_and_fit_peaks_in_mode(k,l)
                if pbar is not None:
                    pbar.update()

    def _find_and_fit_peaks_in_mode(self,k,l):
        """Find and fit peaks in a specific spatial fourier mode.
        
        :param int k:
        :param int l:
        
        """
        
        self.config.setdefault("fitting.search_radius",0.02)
        self.config.setdefault("fitting.mask_radius",0.02)
        self.config.setdefault("fitting.initial_alpha",0.9990)
        self.config.setdefault("fitting.min_alpha",0.50)
        self.config.setdefault("fitting.max_alpha",0.9995)
        self.config.setdefault("fitting.float_peak",True)
        max_layers = self.config.get("layers.max_layers",6)
        
        psd = self.psd[:,k,l]
        
        fit = np.zeros_like(psd)
        mask = np.zeros_like(psd,dtype=np.bool)
        layers = []
        layer_n = 0
        looking = True
        
        while looking:
            
            psd = psd - fit
            looking, layer, mask, fit = find_and_fit_peak(psd,mask,self.template_ft,self.omega,**self.config["fitting"])
            if looking:
                layer_n += 1.0
                layers.append(layer)
            if layer_n >= max_layers:
                looking = False
        
        return layers
    
    
    @property
    def omega(self):
        """docstring for omega"""
        return self.hz / self.rate * 2 * np.pi
        
    def estimate(self):
        """docstring for estimate"""
        self._periodogram()
        self._periodogram_to_phase()
        self._split_atmosphere_and_noise()
        self._create_peak_template()
        self._find_and_fit_peaks()
        
    def finish(self):
        """docstring for finish"""
        pass
        
        
class Periodogram(ConsoleContext):
    """PowerSpectralDistributions"""
    def __init__(self,plan):
        super(Periodogram, self).__init__()
        self.plan = plan
        
    def _show_psd(self,ax,psd,maxhz=50,title="",**kwargs):
        """docstring for _show_psd"""
        if title:
            ax.set_title("Periodogram for {title}".format(title=title))
        ax.set_xlabel("Frequency (Hz)")
        ax.set_ylabel("Power")
        ax.plot(self.plan.hz,np.real(psd),**kwargs)
        ax.set_xlim(-1*maxhz,maxhz)
        ax.set_yscale('log')
        ax.grid(True)
        
    def show_psd(self,ax,k,l,maxhz=50):
        """docstring for show_psd"""
        psd = self.plan.psd[:,k,l]
        self._show_psd(ax,psd,maxhz,title="$k={k:d}$ and $l={l:d}$".format(k=k,l=l))
        
    def show_template(self,ax):
        """Show PSD template"""
        self._show_psd(ax,self.plan.template_ft,title="Template Peak PSD")
        
    def show_fit(self,ax,k,l,maxhz=50):
        """Make a plan show a specific PSD fitting routine."""
        
        self.show_psd(ax,k,l,maxhz)
        
        layers = self.plan._find_and_fit_peaks_in_mode(k,l)
        
        fit = np.zeros_like(self.plan.psd[:,k,l])
        for layer in layers:
            fit += fitter(self.plan.omega,layer["alpha"],layer["variance"],layer["omega"])
        ax.plot(self.plan.hz,fit)
        
    def show_fit_all(self,plt,k,l,maxhz=50):
        """Make a plan show a specific PSD fitting routine."""
        fig = plt.figure()
        ax = fig.add_subplot(111)
        
        layers = self.plan._find_and_fit_peaks_in_mode(k,l)
        psd = np.real(self.plan.psd[:,k,l])
        fit = np.zeros_like(self.plan.psd[:,k,l])
        for i,layer in enumerate(layers):
            i_fit = fitter(self.plan.omega,layer["alpha"],layer["variance"],layer["omega"])
            i_fig = plt.figure()
            i_ax = i_fig.add_subplot(111)
            i_ax.plot(self.plan.hz,i_fit,label="Fit")
            self._show_psd(i_ax,psd - fit - i_fit, label="Residual")
            self._show_psd(i_ax,psd - fit,label="Data",title="Peak {:d} in $k={k:d}$ and $l={l:d}$".format(i,k=k,l=l))
            plt.legend()
            fit += i_fit
            
        ax.plot(self.plan.hz,fit)
        self.show_psd(ax,k,l,maxhz)
    
        