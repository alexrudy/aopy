# -*- coding: utf-8 -*-
# 
#  fmts.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-14.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
"""
FMTS – Fourier Mode Temporal-Spatial Estimator
==============================================

This estimator uses the Fourier Wind Identification scheme to detect individual wind layers in telemtry data.

:class:`FourierModeEstimator`
-----------------------------

.. autoclass:: 
    FourierModeEstimator
    :members:
    :inherited-members:
    :private-members:
    
    
Supporting Functions
--------------------

.. autofunction::
    periodogram
    
.. autofunction::
    find_and_fit_peaks_in_mode
    
.. autofunction::
    pool_find_and_fit_peaks_in_modes
    
.. autofunction::
    find_and_fit_peak
    
.. autofunction::
    fitter

"""

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import warnings
import itertools

import numpy as np

from aopy.util.math import depiston
from aopy.aperture import Aperture
from .core import BaseEstimator
from aopy.util.basic import ConsoleContext
from pyshell.core import Struct
from pyshell.config import DottedConfiguration
from pyshell import getLogger

def periodogram(data, periodogram_length, window=None, half_overlap=True):
    """Make a periodogram from N-dimensional data.
    
    :param ndarray data: The data to be made into a periodogram. The peridogoram will be made across axis 0.
    :param int periodogram_length: The length of the desired periodogram.
    :param ndarray window: The windowing function for the periodogram. If it is `None`, a standard windowing function will be used.
    :param bool half_overlap: Whether to half-overlap the segments of the periodogram.
    
    """
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
    
def pool_find_and_fit_peaks_in_modes(args):
    """An interface to :func:`find_and_fit_peaks_in_mode` which takes a single argument to unpack.
    
    :param args: The tuple of arguments to be unpacked.
    
    Note that the parameter ``identifier`` is used to identify this calculation in multiprocessing pools. Its value is arbitrary. In ``fmts``, this becomes the tuple ``(k,l)``.
    
    To correctly pack arguments::
        
        args = identifier,psd,template,omega,kwargs
        
    """
    identifier,psd,template,omega,kwargs = args
    return (find_and_fit_peaks_in_mode(psd,template,omega,**kwargs), identifier)
    
def find_and_fit_peaks_in_mode(psd,template,omega,max_layers=6,**kwargs):
    """Find and fit peaks in a specific spatial fourier mode.
    
    :param ndarray psd: A power-spectral-distribution on which to find peaks.
    :param ndarray template: A template peak spectrum
    :param ndarray omega: The Omegas which provide the scale to the PSD.
    :param int max_layers: The maximum number of layers to find. Peak fitting might fail earlier and return fewer peaks.
    :keyword kwargs: The keywords are passed through to :func:`find_and_fit_peak`
    :return: A list of layers found in this PSD. Each layer is recorded as a dictionary with the fitting parameters.
    
    """    
    fit = np.zeros_like(psd)
    mask = np.zeros_like(psd,dtype=np.bool)
    layers = []
    layer_n = 0
    looking = True
    
    while looking:
        
        psd = psd - fit
        looking, layer, mask, fit = find_and_fit_peak(psd,mask,template,omega,**kwargs)
        if looking:
            layer_n += 1.0
            layers.append(layer)
        if layer_n >= max_layers:
            looking = False
    
    return layers
    
def find_and_fit_peak(psd,mask,template,omega,
    search_radius=1,mask_radius=1,float_peak=False,
    ialpha=0.99,min_alpha=0,max_alpha=1,maxfev=1e3,min_power=1e-3,**kwargs):
    """Find and fit a single peak in a psd.
    
    :param ndarray psd: A power-spectral-distribution on which to find peaks.
    :param ndarray mask: A binary mask to block out the PSD. This is passed back and forth.
    :param ndarray template: A template peak spectrum
    :param ndarray omega: The Omegas which provide the scale to the PSD.
    :param int max_layers: The maximum number of layers to find. Peak fitting might fail earlier and return fewer peaks.
    :keyword kwargs: The keywords are passed through to :func:`find_and_fit_peak`    
    
    """
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
    est_omega = omega[max_i]
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
            sigma=weights,full_output=True,maxfev=int(maxfev))
        est_omega = popt[2]
    else:
        popt, pcov, infodict, errmsg, ier = curvefit(fitter,omega,np.real(psd),p0,
            sigma=weights,args=(np.real(est_omega),),full_output=True,maxfev=int(maxfev))
    
    if popt[1] <= min_power:
        log.warning("Peak Power is negative! %g",popt[1])
        success = False
    elif popt[0] < min_alpha or popt[0] > max_alpha:
        log.warning("Alpha out of range! %.3f",popt[0])
        success = False
    elif ier not in [1,2,3,4]:
        log.warning("Fitting Failure: %d: %s" % (ier,errmsg))
        success = False
    elif success is None:
        success = True
        log.info("Found a peak at alpha=%f omega=%f, power=%g",popt[0],est_omega,popt[1])
        fit_psd = fitter(omega,popt[0],popt[1],est_omega)
        layer["alpha"] = popt[0]
        layer["omega"] = est_omega
        layer["variance"] = popt[1]
        layer["rms"] = np.sqrt(np.sum(fit_psd))
        mask = (mask | (np.abs(omega - est_omega) < mask_radius))
    else:
        success = False
    
    log.debug("{}:{}".format(ier,errmsg))
    
    return success, layer, mask, fit_psd
    
    
def fitter(x,alpha,peak,center):
    """Our mystery fitting function."""
    f = peak/(1 - 2*alpha*np.cos(x-center) + alpha**2.0)
    return f
    
def peaks_to_table(peakgrid,npeaks):
    """docstring for _layers_to_table"""
    k = np.zeros((npeaks,),dtype=np.int)
    l = np.zeros((npeaks,),dtype=np.int)
    alpha = np.zeros((npeaks,),dtype=np.float)
    omega = np.zeros((npeaks,),dtype=np.float)
    power = np.zeros((npeaks,),dtype=np.float)
    rms = np.zeros((npeaks,),dtype=np.float)
    
    pol = 0
    for k_i in range(peakgrid.shape[0]):
        for l_i in range(peakgrid.shape[1]):
            for layer in peakgrid[k_i,l_i]:
                k[pol] = k_i
                l[pol] = l_i
                alpha[pol] = layer["alpha"]
                omega[pol] = layer["omega"]
                power[pol] = layer["variance"]
                rms[pol] = layer["rms"]
                pol += 1
    return np.rec.fromarrays([k,l,alpha,omega,power,rms],names=["k","l","alpha","omega","power","rms"])
    
def peaks_from_table(table,shape):
    """Convert a layer-table back to a layer grid."""
    peaks_grid = np.empty(shape,dtype=object)
    npeaks = np.zeros(shape,dtype=np.int)
    for k_i in range(shape[0]):
        for l_i in range(shape[1]):
            select = (table['k'] == k_i) & (table['l'] == l_i)
            peaks = []
            for peak in table[select]:
                peaks.append({
                'alpha' : peak['alpha'],
                'omega' : peak['omega'],
                'variance' : peak['power'],
                'rms' : peak['rms']
                })
            peaks_grid[k_i,l_i] = peaks
            npeaks[k_i,l_i] = len(peaks)
    return peaks_grid, npeaks
    
def peaks_array_from_grid(peaks,npeaks):
    """docstring for peaks_array_from_table"""
    peaks_grid = np.zeros(peaks.shape + (np.max(npeaks),4))
    for k,l in itertools.product(*map(range,peaks.shape)):
        if npeaks[k,l] > 0:
            peaks_grid[k,l,:npeaks[k,l],:] = np.array([ [peak["alpha"], peak["omega"], peak["variance"], peak["rms"]] for peak in peaks[k,l]])
    return peaks_grid
    
    
def create_layer_metric(peaks,npeaks,omega,klshape,rate,maxv=40,deltav=0.5,D=0.56,frac=0.4,lowest_hz=2.0,dist_hz=1.0):
    """Create a layer metric for finding individual layers.

    :param ndarray peaks: A full peak grid.
    :param ndarray omega: Scaling omega array.
    :param tuple klshape: The shape of the PSD
    :param float rate: The sampling rate.
    :param float maxv: The maximum velocity to search for.    
    :param float deltav: Velocity steps for search
    :param float D: Telescope Diameter
    :param float lowest_hz: The lowested detected hz.
    
    """
    log = getLogger(__name__+'create_layer_metric')    
    import scipy.fftpack
    peaks_hz = peaks_array_from_grid(peaks,npeaks)[...,1] * rate / (2.0 * np.pi)
    print(np.max(peaks_hz),np.min(peaks_hz))
    minv = -1*maxv
    numv = (maxv-minv)//deltav + 1.0
    maxf = np.max(peaks_hz)
    ff = scipy.fftpack.fftshift(scipy.fftpack.fftfreq(klshape[0],D))
    vv = np.arange(numv) * deltav + minv
    log.debug("Created ff: %r vv: %r" % (ff.shape,vv.shape))
    fx,fy, vx, vy = np.meshgrid(ff,ff,vv,vv)
    # log.debug("Grid-Zeros: %g, %g, %g, %g" % (fx[1,2,3,4],fy[1,2,3,4],vx[1,2,3,4],vy[1,2,3,4]))
    log.debug("Created Grids")
    
    valid = np.ones(ff.shape + ff.shape,dtype=np.int)
    valid[0,0] = 0.0
    min_layer_hz_npeaks = frac * np.sum(valid)
    log.debug("Created Validity Criterion")
    
    layer_peak_hz = fx * vx + fy * vy
    log.debug("Calculated Layer Hz")
    log.debug("[%g,%g]" % (np.min(fx),np.max(fx)))
    possible = np.abs(layer_peak_hz) >= lowest_hz
    possible &= (min_layer_hz_npeaks <= np.sum(possible,axis=(0,1)))
    possible = (possible[:,:,np.newaxis,:,:] & (np.abs(peaks_hz[:,:,:,np.newaxis,np.newaxis]) >= lowest_hz))
    no_possible = np.sum(possible,axis=2) == 0.0
    matched = np.zeros_like(vx,dtype=np.int)
    matched = (np.abs(layer_peak_hz[:,:,np.newaxis,:,:] - peaks_hz[:,:,:,np.newaxis,np.newaxis]) <= dist_hz) & (possible)
    
    metric_filtered = np.any(matched,axis=2).astype(np.int)
    metric_filtered[no_possible] = 0.0
    possible_filtered = np.any(possible,axis=2).astype(np.int)
    possible_filtered[no_possible] = 1.0
    print(np.max(metric_filtered),np.max(possible),possible_filtered.shape)
    metric = metric_filtered/possible_filtered
    possible_filtered[no_possible] = 0.0
    collapse_possible = np.sum(possible_filtered,axis=(0,1))
    collapse_metric = np.sum(metric_filtered,axis=(0,1)).astype(np.float)/collapse_possible.astype(np.float)
    
    return collapse_metric, metric, collapse_possible, possible_filtered, vv, ff, peaks_hz, matched, layer_peak_hz

class FourierModeEstimator(BaseEstimator):
    """Estimates wind using the Fourier Mode Timeseries Method"""
    def __init__(self,config=(__name__,"fmts.yml")):
        super(FourierModeEstimator, self).__init__()
        self.config = DottedConfiguration.make(config)
    
    def setup(self,case):
        """Setup the estimator by providing a case object.
        
        :param case: The WCAOCase object.
        :return: ``self``
        
        """
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
        self.hz = np.mgrid[-1*per_length/2:per_length/2] / per_length * self.rate
        self.psd = scipy.fftpack.fftshift(psd,axes=0)
        
    def _periodogram_to_phase(self):
        """Convert the periodogram to phase."""
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
        with warnings.catch_warnings():
            warnings.simplefilter('ignore')
            noise_psds = np.median(self.psd[ca:cb,...],axis=0)
            noise_psds[np.isnan(noise_psds)] = 0.0
            noise_stds = np.std(self.psd[ca:cb,...],axis=0)
            noise_stds[np.isnan(noise_stds)] = 0.0
        mask = self.psd <= (noise_psds + 2.0*noise_stds)
        self.log.debug("Masking %d noisy positions from PSDs" % np.sum(mask))
        self.psd[mask] = 0.0
        
    def _save_periodogram(self,filename,clobber=False):
        """Save the periodogram to a fits file."""
        from astropy.io import fits
        psd = np.array([np.real(self.psd),np.imag(self.psd)])
        HDU = fits.PrimaryHDU(psd)
        HDU.header['CaseName'] = self.case.casename
        # HDU.header['Hash'] = self.config.hash
        HDU.header['rate'] = self.rate
        HDU_hz = fits.ImageHDU(self.hz)
        HDUList = fits.HDUList([HDU,HDU_hz])
        HDUList.writeto(filename,clobber=clobber)
        
    def _load_periodogram(self,filename):
        """Load the periodogram from a fits file."""
        from astropy.io import fits
        
        with fits.open(filename) as FitsFile:
            self.psd = FitsFile[0].data[0] + 1j * FitsFile[0].data[1]
            self.rate = FitsFile[0].header['rate']
            length = self.psd.shape[0]
            self.hz = FitsFile[1].data
        
    def _create_peak_template(self):
        """Make peak templates for correlation fitting"""
        import scipy.fftpack
        
        self.template = periodogram(np.ones((self.psd.shape[0]*self.psd.shape[0]),dtype=np.complex),self.psd.shape[0])
        self.template_ft = np.conj(scipy.fftpack.fftshift(scipy.fftpack.fft(self.template)))
        self.peaks = np.empty(self.psd.shape[1:],dtype=object)
        self.npeaks = np.empty(self.psd.shape[1:],dtype=np.int)
        
        
    def _find_and_fit_peaks(self):
        """Find and fit peaks in each PSD"""
        from astropy.utils.console import ProgressBar
        from itertools import product
        modes = list(product(range(self.psd.shape[1]),range(self.psd.shape[2])))
        kwargs = dict(self.config["fitting"])
        psd = self.psd
        template = self.template_ft
        omega = self.omega
        
        args = [ ((k,l),psd[:,k,l],template,omega,kwargs) for k,l in modes ]
        peaks = ProgressBar.map(pool_find_and_fit_peaks_in_modes,args,multiprocess=True)
        for peak_mode,ident in peaks:
            k,l = ident
            self.peaks[k,l] = peak_mode
            self.npeaks[k,l] = len(peak_mode)
        self.log.info("Found %d peaks",np.sum(self.npeaks))
    
    
    def _find_and_fit_peaks_in_mode(self,k,l):
        """This method finds and fits independent peaks in single layers, similar to the way :meth:`_find_and_fit_peaks` works, but operating independently.
        
        :param k: The spatial fourier `k` mode number.
        :param l: The spatial fourier `l` mode number.
        
        """
        kwargs = dict(self.config["fitting"])
        psd = self.psd[:,k,l]
        template = self.template_ft
        omega = self.omega
        peaks = find_and_fit_peaks_in_mode(psd,template,omega,**kwargs)
        self.peaks[k,l] = peaks
        self.npeaks[k,l] = len(peaks)
        return peaks
        
    
    def _save_peaks_to_table(self,filename,clobber=False):
        """Save found peaks to a table."""
        from astropy.io import fits
        tbl_hdu = fits.new_table(peaks_to_table(self.peaks,np.sum(self.npeaks)))
        tbl_hdu.writeto(filename,clobber=clobber)
        
    def _read_peaks_from_table(self,filename):
        """docstring for _read_peaks_from_table"""
        from astropy.io import fits
        with fits.open(filename) as FitsFile:
            table = FitsFile[1].data
            self.peaks, self.npeaks = peaks_from_table(table,self.psd.shape[1:])
        
    def _fit_peaks_to_metric(self):
        """Fit each peak to a metric."""
        self.metric, self.fullmetric, self.possible, self.fullpossible, self.vv, self.ff, self.peaks_hz, self.matched, self.layer_peak_hz = create_layer_metric(self.peaks,self.npeaks,self.omega,self.psd.shape[1:],self.rate)
    
    
    @property
    def omega(self):
        """Omega"""
        return (self.hz / self.rate) * 2.0 * np.pi
        
    def estimate(self):
        """Perform the full estimate."""
        self._periodogram()
        self._periodogram_to_phase()
        self._split_atmosphere_and_noise()
        self._create_peak_template()
        self._find_and_fit_peaks()
        self._fit_peaks_to_metric()
        
    def finish(self):
        """Save the results back to the original WCAOCase"""
        pass
        
        
class Periodogram(ConsoleContext):
    """This is an object for plotting periodograms.
    
    :param plan: The FMTS plan to use.
    
    """
    def __init__(self,plan):
        super(Periodogram, self).__init__()
        self.plan = plan
        self.log = getLogger(__name__)
        
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
        
    def show_psd(self,ax,k,l,maxhz=50,title=None,**kwargs):
        """Show an individual PSD.
        
        :param ax: A matplotlib axes object on which to plot.
        :param int k: ``k``-mode.
        :param int l: ``l``-mode.
        :param float maxhz: The maximum ``hz`` value to display.
        
        """
        title = "$k={k:d}$ and $l={l:d}$".format(k=k,l=l) if title is None else title
        psd = self.plan.psd[:,k,l]
        self._show_psd(ax,psd,maxhz,title=title,**kwargs)
        
    def show_template(self,ax,k,l):
        """Show PSD template.
        
        :param ax: A matplotlib axes object on which to plot.
        
        """
        import scipy.signal
        # self._show_psd(ax,self.plan.template_ft,title="Template Peak PSD")
        correl = scipy.signal.fftconvolve(self.plan.template_ft,self.plan.psd[:,k,l],mode='same')
        ax.plot(self.plan.hz,correl)
        
    def show_peak_fit(self,ax,k,l,maxhz=50,stopafter=None,correlax=None):
        """Make a plan show a specific PSD fitting routine.
        
        :param ax: A matplotlib axes object on which to plot.
        :param int k: ``k``-mode.
        :param int l: ``l``-mode.
        :param float maxhz: The maximum ``hz`` value to display.
        
        """
        import scipy.signal
        
        self.show_psd(ax,k,l,maxhz,label="Raw PSD")
        peaks = self.plan.peaks[k,l]
        print("Showing %d peaks" % len(peaks))
        psd = np.real(self.plan.psd[:,k,l])
        fit = np.zeros_like(psd,dtype=np.float)
        for i,peak in enumerate(peaks):
            this_psd = psd-fit
            this_psd[this_psd <= 0.0] = 0.0
            Ifit = fitter(self.plan.omega,peak["alpha"],peak["variance"],peak["omega"])
            peak_hz = peak["omega"] * self.plan.rate / (2.0 * np.pi)
            print("Plotting peak %d, alpha=%g, hz=%g, power=%g" % (i, peak["alpha"], peak_hz, peak["variance"]))
            fitline, = ax.plot(self.plan.hz,this_psd,'--')
            fit += Ifit
            line, = ax.plot(self.plan.hz,Ifit,':',label="Peak %d" % i, color=fitline.get_color())
            if correlax is not None:
                correl = scipy.signal.fftconvolve(self.plan.template_ft,this_psd,mode='same')
                correlax.plot(self.plan.hz,correl)
            if stopafter is not None and i == stopafter:
                break
        ax.plot(self.plan.hz,fit,"-.",label="Total Fit")
        ax.legend(*ax.get_legend_handles_labels())
        
    def show_fit_all(self,plt,k,l,maxhz=50):
        """Make a plan show a specific PSD fitting routine.
        
        :param plt: A matplotlib module to plot from.
        :param int k: ``k``-mode.
        :param int l: ``l``-mode.
        :param float maxhz: The maximum ``hz`` value to display.
        
        """
        fig = plt.figure()
        ax = fig.add_subplot(111)
        peaks = self.plan.peaks[k,l]
        psd = np.real(self.plan.psd[:,k,l])
        fit = np.zeros_like(self.plan.psd[:,k,l])
        for i,peak in enumerate(peaks):
            i_fit = fitter(self.plan.omega,peak["alpha"],peak["variance"],peak["omega"])
            i_fig = plt.figure()
            i_ax = i_fig.add_subplot(111)
            i_ax.plot(self.plan.hz,i_fit,label="Fit")
            self._show_psd(i_ax,psd - fit - i_fit, label="Residual")
            self._show_psd(i_ax,psd - fit,label="Data",title="Peak {:d} in $k={k:d}$ and $l={l:d}$".format(i,k=k,l=l))
            plt.legend()
            fit += i_fit
            
        ax.plot(self.plan.hz,fit,label="Fit")
        # ax.plot(self.plan.hz,fitter(self.plan.omega,peak[0]["alpha"],peak[0]["variance"],peak[0]["omega"]))
        self.show_psd(ax,k,l,maxhz)
        
    def show_peaks(self,fig):
        """docstring for show_peaks"""
        ax = fig.add_subplot(1,1,1)
        peaks_grid = self.plan.peaks_hz[:,:,:]
        peaks_grid = np.ma.array(peaks_grid,mask=(np.abs(peaks_grid) <= 2.0))
        peaks_grid = peaks_grid[:,:,0]
        Im = ax.imshow(peaks_grid,interpolation='nearest')
        fig.colorbar(Im)
        
    def show_fit(self,fig,vxvy=None):
        """docstring for show_fit"""
        if vxvy is None:
            vx,vy = np.unravel_index(np.argmax(self.plan.metric),self.plan.metric.shape)
        else:
            vx,vy = vxvy
        print("Showing layer at v = [%.1f,%.1f]" % (self.plan.vv[vx],self.plan.vv[vy]))
        extent = [np.min(self.plan.ff),np.max(self.plan.ff),np.min(self.plan.ff),np.max(self.plan.ff)]
        ax1 = fig.add_subplot(2,2,1)
        ax2 = fig.add_subplot(2,2,2)
        ax3 = fig.add_subplot(2,2,3)
        ax4 = fig.add_subplot(2,2,4)
        
        fit_peaks = np.copy(self.plan.peaks_hz)
        fit_peaks = np.max(fit_peaks,axis=2)
        matched_peaks = np.sum(self.plan.matched[:,:,:,vx,vy],axis=2)
        fit_peaks[matched_peaks == 0] = np.nan
        possible_peaks = self.plan.layer_peak_hz[:,:,vx,vy]
        possible = self.plan.fullpossible[:,:,vx,vy]
        
        vmin = -20
        vmax = 20
        nmin = 0
        nmax = np.max(possible_peaks)
        ax1.imshow(fit_peaks,extent=extent,interpolation='nearest',vmin=vmin,vmax=vmax)
        ax1.set_title("Fit Peaks")
        
        ax2.imshow(matched_peaks,extent=extent,interpolation='nearest',vmin=nmin,vmax=nmax)
        ax2.set_title("N Found Peaks")
        
        
        Im = ax3.imshow(possible_peaks,extent=extent,interpolation='nearest',vmin=vmin,vmax=vmax)
        ax3.set_title("Theory")
        fig.colorbar(Im)
        
        ax4.imshow(possible,extent=extent,interpolation='nearest',vmin=nmin,vmax=nmax)
        ax4.set_title("N Possible Peaks")
        
    def show_metric(self,ax):
        """Show a specific metric"""
        # print(np.max(self.plan.metric),np.min(self.plan.metric))
        extent = [np.min(self.plan.vv),np.max(self.plan.vv),np.min(self.plan.vv),np.max(self.plan.vv)]
        Image = ax.imshow(self.plan.metric,extent=extent,interpolation='nearest',vmin=0.0,vmax=1.0)
        ax.set_title("Peak Metric")
        return Image
        
    def show_mask(self,ax):
        """docstring for show_mask"""
        extent = [np.min(self.plan.vv),np.max(self.plan.vv),np.min(self.plan.vv),np.max(self.plan.vv)]
        Image = ax.imshow(self.plan.possible,extent=extent,interpolation='nearest')
        ax.set_title("Peak Mask")
        return Image
    
        