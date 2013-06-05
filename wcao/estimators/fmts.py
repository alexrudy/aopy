# -*- coding: utf-8 -*-
# 
#  fmts.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-14.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
"""
:mod:`wcao.estimators.fmts` – Fourier Mode Temporal-Spatial Estimator
---------------------------------------------------------------------

This estimator uses the Fourier Wind Identification scheme to detect individual wind layers in telemtry data.

:class:`FourierModeEstimator`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. autoclass:: 
    FourierModeEstimator
    :members:

:class:`FourierModeEstimator` – Operational Functions
*****************************************************

.. autoclass::
    FourierModeEstimator
    :exclude-members: setup, estimate, finish, omega
    :inherited-members:
    :private-members:
    
Supporting Functions
********************

.. autofunction::
    periodogram
    
.. autofunction::
    find_and_fit_peaks_in_mode
    
.. autofunction::
    pool_find_and_fit_peaks_in_modes
    
.. autofunction::
    find_and_fit_peak
    
.. autofunction::
    create_layer_metric
    
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
    psd = psd / num_intervals
    psd = psd / np.sum(window**2.0,axis=0)
    psd = psd / periodogram_length
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
    
def find_and_fit_peaks_in_mode(psd,template,omega,max_peaks=6,**kwargs):
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
    peaks = []
    
    for n in range(max_peaks):
        psd = psd - fit
        looking, peak, mask, fit = find_and_fit_peak(psd,mask,template,omega,**kwargs)
        if not looking:
            break
        peaks.append(peak)
    
    return peaks
    
def floatingmax(data,scalar):
    """Find a center point using a three-point peak fit.
    
    :param ndarray data: The data which has a peak to be found.
    :param ndarray scalar: A scalar along which to measure the peak.
    :return: ``(data_v,scalar_v,data_f)`` where ``data_v`` is the value of the peak (interpolated)
    
    """
    import scipy.interpolate
    assert scalar.shape == data.shape
    data_i = np.argmax(data)
    poles = data[np.mod(np.array([-1, 0 , 1]) + data_i,data.shape[0])]
    bot = (poles[0] + poles[2] - 2.0 * poles[1])
    top = (poles[0] - poles[2])
    if bot == 0.0:
        f_pos = poles[1]
    else:
        f_pos = 0.5 *  top/bot
    data_f = (data_i + f_pos) % data.shape[0]
    data_f = data.size - 1 if data_f > (data.size - 1) else data_f
    data_v = scipy.interpolate.interp1d(np.arange(data.size),data,kind='linear')(data_f)
    scalar_v = scipy.interpolate.interp1d(np.arange(scalar.size),scalar,kind='linear')(data_f)
    return data_v, scalar_v, data_f
    
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
    correl = np.real(scipy.fftpack.ifft(template * scipy.fftpack.fft(psd)))
    max_i = np.argmax(correl)
    max_v = np.max(correl)
    success = None
    peak = {}
    fit_psd = np.empty_like(psd)
    
    #TODO: Sub-pixel matching for the peak!
    est_correl, est_omega, est_pos = floatingmax(np.real(correl),omega)
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
    fit_psd = fitter(omega,popt[0],popt[1],est_omega)
    if popt[1] <= min_power:
        log.warning("Peak Power is too small! %g",popt[1])
        success = False
    elif np.max(fit_psd) > 10.0 * np.max(np.real(psd)*weights):
        log.warning("Peak Power is much greater than PSD! %g >> %g", popt[1],np.max(np.real(psd)*weights))
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
        peak["alpha"] = popt[0]
        peak["omega"] = est_omega
        peak["variance"] = popt[1]
        peak["rms"] = np.sqrt(np.sum(fit_psd))
        mask = (mask | (np.abs(omega - est_omega) < mask_radius))
    else:
        success = False
    
    log.debug("{}:{}".format(ier,errmsg))
    
    return success, peak, mask, fit_psd
    
    
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
    
    
def create_layer_metric(peaks,npeaks,omega,klshape,rate,maxv=100,deltav=5,frac=0.5,lowest_hz=2.0,dist_hz=1.0,D=1):
    """Create a layer metric for finding individual layers.

    :param ndarray peaks: A full peak grid.
    :param ndarray omega: Scaling omega array.
    :param tuple klshape: The shape of the PSD
    :param float rate: The sampling rate.
    :param float maxv: The maximum velocity to search for.    
    :param float deltav: Velocity steps for search
    :param float D: Telescope Diameter
    :param float lowest_hz: The lowested detected hz.
    :param float dist_hz: The distance, in hz, for which to count a detection.
    
    The grids in this method have 4 or 5 axes. The axes are as follows:
    
    1. The x-direction spatial frequency
    2. The y-direction spatial frequency
    3. The x-direction velocity
    4. The y-direction velocity
    5. (Optional) The direction of peaks detected.
    
    """
    # Setup the algorithm
    log = getLogger(__name__+'.create_layer_metric')    
    import scipy.fftpack
    
    # Data
    # TODO: Figure out why this shift is necessary.
    # Note: The peaks grid is selected on column 1 so that the omega paramter is returned.
    peaks_hz = scipy.fftpack.fftshift(peaks_array_from_grid(peaks,npeaks)[...,1] * rate / (2.0 * np.pi),axes=(0,1))[:,:,np.newaxis,np.newaxis,:]
    log.debug("Created Peaks")
    
    # Search Grid
    minv = -1*maxv
    numv = (maxv-minv)//deltav + 1.0
    maxf = np.max(peaks_hz)
    ff = scipy.fftpack.fftshift(scipy.fftpack.fftfreq(klshape[0],D))
    vv = np.arange(numv) * deltav + minv
    log.debug("Created ff: %r vv: %r" % (ff.shape,vv.shape))
    fx,fy, vx, vy = np.meshgrid(ff,ff,vv,vv)
    log.debug("Created Grids")
    
    # Validity Criterion
    valid = np.ones(ff.shape + ff.shape,dtype=np.int)
    valid[0,0] = 0.0
    min_layer_hz_npeaks = frac * np.sum(valid)
    log.debug("Created Validity Criterion")
    
    # Theoretical Data
    layer_peak_hz = fx * vx + fy * vy
    log.debug("Calculated Layer Hz")
    
    # Possible Match Peaks
    possible = np.abs(layer_peak_hz) >= lowest_hz
    possible &= (min_layer_hz_npeaks <= np.sum(possible,axis=(0,1)))
    valid = (np.abs(peaks_hz) >= lowest_hz)
    log.debug("Calculated Possible Peaks")
    
    # Matched Peaks
    matched = (np.abs(layer_peak_hz[...,np.newaxis] - peaks_hz) <= dist_hz) & possible[...,np.newaxis] & valid
    log.debug("Matched Peaks")
    # Calculation of the Metric
    
    # Collapsing along N peaks.
    matched_filtered = np.any(matched,axis=-1).astype(np.int)
    possible_filtered = np.copy(possible)
    no_possible = possible == 0.0
    
    
    # Calculating metric at every spatial frequency
    possible_filtered[no_possible] = 1.0
    metric_filtered = matched_filtered/possible_filtered
    possible_filtered[no_possible] = 0.0
    
    # Collapsing along spatial frequencies
    matched_collapsed = np.sum(matched_filtered,axis=(0,1)).astype(np.float)
    possible_collapsed = np.sum(possible_filtered,axis=(0,1)).astype(np.float)
    no_possible_collapsed = (possible_collapsed == 0)
    
    # Caclulating the summed metric for each velocity
    possible_collapsed[no_possible_collapsed] = 1.0
    collapse_metric = matched_collapsed/possible_collapsed
    possible_collapsed[no_possible_collapsed] = 0.0
    
    log.debug("Calculated Metric")
    
    infodict = {
        'ff' : ff,
        'vv' : vv,
        'peaks_hz' : peaks_hz,
        'full_matched' : matched,
        'fv_matched' : matched_filtered,
        'fv_layer_hz' : layer_peak_hz,
        'fv_possible' : possible_filtered,
        'v_matched' : matched_collapsed,
        'v_possible' : possible_collapsed,
        'v_metric' : collapse_metric,
    }
    
    return collapse_metric, possible_collapsed, matched_collapsed, infodict
    

def recenter(x,y,data,box):
    """Recenter a point ``x,y`` using a bounding box.
    
    :param int x: The x position.
    :param int y: The y position.
    :param ndarray data: The data to recenter.
    :param ndarray box: The size of the box to use.
    
    Uses :func:`scipy.ndimage.measurements`
    """
    import scipy.ndimage.measurements
    
    cen_xm = x - box//2 if x - box//2 >= 0 else 0
    cen_ym = y - box//2 if y - box//2 >= 0 else 0
    cen_xp = x + box//2 if x + box //2 < data.shape[0] else data.shape[0] - 1
    cen_yp = y + box//2 if y + box//2 < data.shape[1] else data.shape[1] - 1
    
    com_x,com_y = scipy.ndimage.measurements.center_of_mass(data[cen_xm:cen_xp,cen_ym:cen_yp])
    
    c_x = com_x + cen_xm
    c_y = com_y + cen_ym
    
    return c_x, c_y
    

def find_layers(metric,vv,spacing=10,min_layer_threshold=0.75,centroid=None):
    """Find individual layers.
    
    :param ndarray metric: The metric to use.
    :param ndarray vv: The scale for the metric.
    :param float spacing: The minimum distance between peaks.
    :param float min_layer_threshold: The minimum metric threshold
    :param float centroid: The size of the box for centroiding. Defaults to ``spacing``.
    
    Uses :func:`skimage.feature` and :func:`recenter`.
    
    """
    log = getLogger(__name__ + ".find_layers")
    import skimage.feature
    centroid = spacing if centroid is None else centroid
    log.debug("Finding Peaks")
    result = skimage.feature.peak_local_max(metric,min_distance=spacing,threshold_abs=min_layer_threshold)
    layers = []
    layer_pos = []
    log.debug("Recentering %d Peaks" % result.shape[0])
    for peak_x,peak_y in result:
        if np.array(layer_pos).ndim != 2 or (np.sum(np.power(np.array(layer_pos) - np.array([peak_y,peak_x]),2),axis=1) >= np.power(spacing,2)).all():            
            com_y, com_x = recenter(peak_x,peak_y,metric,centroid)
            vx = np.interp(com_x,np.arange(vv.shape[0]),vv)
            vy = -1*np.interp(com_y,np.arange(vv.shape[0]),vv)
            pvx = vx + 0.25
            pvy = vy# - 0.25
            layers.append({
                'vx' : vx,
                'vy' : vy,
                'ivx' : peak_x,
                'ivy' : peak_y,
                'pvx': pvx,
                'pvy': pvy,
                'm' : metric[peak_x,peak_y],
            })
            layer_pos.append([peak_x,peak_y])
    return layers
    

class FourierModeEstimator(BaseEstimator):
    """Estimates wind using the Fourier Mode Timeseries Method"""
    def __init__(self,config=(__name__,"fmts.yml")):
        super(FourierModeEstimator, self).__init__()
        self._config = DottedConfiguration.make(config)
        self.initialze()
    
    def setup(self,case):
        """Setup the estimator by providing a case object.
        
        :param case: The WCAOCase object.
        :return: ``self``
        
        """
        self.case = case
        self.rate = self.case.rate
        self.config = self.case.config
        self.config.imerge(self._config)
        
        self._fmode = self.case.telemetry.fmode
        if hasattr(self.case.telemetry,'_fmode_dmtransfer'):
            self._fmode_dmtransfer = self.case.telemetry._fmode_dmtransfer
        else:
            self._fmode_dmtransfer = np.ones_like(self._fmode[0])
        return self
    
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
        self._find_layers()
        
    def finish(self):
        """Save the results back to the original WCAOCase"""
        from wcao.data.fmtsmap import WCAOFMTSMap
        self.case.addresult(self ,WCAOFMTSMap, "FT")
        self.initialze()
        
        
    def initialze(self):
        """Initialize internal variables."""
        # Base Data
        self.case = None
        self.rate = None
        self._fmode = None
        self._fmode_dmtransfer = None
        
        # Periodogram
        self.psd = None
        self.hz = None
        
        # Peaks
        self.peaks = None
        self.npeaks = None
        
        self.metric = None
        self.possible = None
        self.matched = None
        self.match_info = None
        
        self.layers = None
    
    def _periodogram(self):
        """Create a periodogram from a set of fourier modes."""
        import scipy.fftpack
        total_length = self.case.telemetry.nt
        per_length = self.config["FMTS.periodogram.length"]
        if self.config.get("FMTS.periodogram.mean_remove",True):
            fmode = self._fmode - np.mean(self._fmode,axis=0)[np.newaxis,:,:]
        psd = periodogram(fmode, per_length,
            half_overlap=self.config.get("FMTS.periodogram.half_overlap",True))
        psd *= self._fmode_dmtransfer[np.newaxis,:psd.shape[1],:psd.shape[2]]
        self.hz = np.mgrid[-1*per_length/2:per_length/2] / per_length * self.rate
        self.psd = scipy.fftpack.fftshift(psd,axes=0)
        
    def _periodogram_to_phase(self):
        """Convert the periodogram to phase."""
        if self.case.telemetry.data_config["type"] == 'closed-loop-dm-commands':
            import scipy.fftpack
            s = 1j*2.0*np.pi*(self.hz)
            bigT = 1.0/self.rate
            wfs_cont = (1.0 - np.exp(-bigT*s))/(bigT*s)
            wfs_cont[s == 0] = 1.0
            dm_cont = wfs_cont
            delay_cont = np.exp(-1.0*self.config["system.tau"]*s)
            zinv = np.exp(-1.0*bigT*s)
            cofz = self.config["system.gain"]/(1.0 - self.config["system.integrator_c"]*zinv)
            delay_term = wfs_cont*dm_cont*delay_cont
            tf_to_convert_to_phase = np.abs((1 + delay_term*cofz)/(cofz))**2.0
        else:
            tf_to_convert_to_phase = np.ones_like(self.hz)
        
        self.psd *= (tf_to_convert_to_phase)[:,np.newaxis,np.newaxis]
    
    def _split_atmosphere_and_noise(self):
        """Split PSDs into atmosphere and noise terms."""
        if self.config.get("FMTS.noise.remove",True):
            import scipy.fftpack
            per_length = self.config["FMTS.periodogram.length"]
            wid = per_length*self.config["FMTS.noise.frac"]//2
            ca = per_length//2 - wid
            cb = per_length//2 + wid
            ns = self.config["FMTS.noise.n_sigma"]
            with warnings.catch_warnings():
                warnings.simplefilter('ignore')
                noise_psds = np.median(scipy.fftpack.fftshift(self.psd,axes=0)[ca:cb,...],axis=0)
                noise_psds[np.isnan(noise_psds)] = 0.0
                noise_stds = np.std(scipy.fftpack.fftshift(self.psd,axes=0)[ca:cb,...],axis=0)
                noise_stds[np.isnan(noise_stds)] = 0.0
            mask = self.psd < (noise_psds + ns*noise_stds)[np.newaxis,...]
            self.log.info("Masking %d noisy positions from PSDs" % np.sum(mask))
            np.savetxt("noise.txt",noise_psds)
            np.savetxt("noise_sig.txt",noise_stds)
            self.psd[mask] = 0.0
        
    def _save_periodogram(self,filename,clobber=False):
        """Save the periodogram to a fits file."""
        from astropy.io import fits
        psd = np.array([np.real(self.psd),np.imag(self.psd)])
        HDU = fits.PrimaryHDU(psd)
        HDU.header['CaseName'] = self.case.casename
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
        
        template = periodogram(np.ones((self.psd.shape[0]*self.psd.shape[0]),dtype=np.complex),self.psd.shape[0])
        self.template_ft = np.conj(scipy.fftpack.fftshift(scipy.fftpack.fft(template)))
        self.peaks = np.empty(self.psd.shape[1:],dtype=object)
        self.npeaks = np.empty(self.psd.shape[1:],dtype=np.int)
        
        
    def _find_and_fit_peaks(self):
        """Find and fit peaks in each PSD"""
        from astropy.utils.console import ProgressBar
        from itertools import product
        
        modes = list(product(range(self.psd.shape[1]),range(self.psd.shape[2])))
        kwargs = dict(self.config["FMTS.fitting"])
        psd = self.psd
        template = self.template_ft
        omega = self.omega
        
        args = [ ((k,l),psd[:,k,l],template,omega,kwargs) for k,l in modes ]
        peaks = ProgressBar.map(pool_find_and_fit_peaks_in_modes,args,multiprocess=self.config["FMTS.multiprocess"])
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
        kwargs = dict(self.config["FMTS.fitting"])
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
        self.metric, self.possible, self.matched, self.match_info = create_layer_metric(self.peaks,self.npeaks,self.omega,
            self.psd.shape[1:],self.rate,D=self.case.subapd,**self.config["FMTS.metric"])
        
    def _find_layers(self):
        """Find layers"""
        self.layers = find_layers(self.metric,self.match_info["vv"],**self.config["FMTS.layers"])
        
        

    
        