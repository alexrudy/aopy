# -*- coding: utf-8 -*-
# 
#  fmtsutil.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-07-15.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import sys
import itertools

import numpy as np

from pyshell.loggers import getLogger
from aopy.util.math import lodtorec, rectolod
from wcao.data.estimator import set_wcao_header_values, verify_wcao_header_values
from wcao.data.windmap import set_v_metric_headers, read_v_metric_headers, save_map, load_map

def peaks_to_table(peakgrid,npeaks=None):
    """Create a table from a grid of peaks.
    
    The grid of peaks should be a ``k`` x ``l`` array of lists of peak properties.
    The table will be a record array with columns ``k``, ``l``, :math:`\\alpha`, :math:`\omega`, power, and fit ``rms``.
    
    :param ndarray peakgrid: The grid of peaks to form into a table.
    :param int npeaks: The total number of peaks in the grid. If it isn't provided, it will be found, in order `N`.
    :return: Record array of peaks.
    
    This function is the inverse of :func:`peaks_from_table`.
    
    """
    if npeaks is None:
        npeaks = sum([ len(x) for x in peakgrid.flat ])
    k = np.zeros((npeaks,),dtype=np.int) 
    l = np.zeros((npeaks,),dtype=np.int)
    alpha = np.zeros((npeaks,),dtype=np.float)
    omega = np.zeros((npeaks,),dtype=np.float)
    power = np.zeros((npeaks,),dtype=np.float)
    rms = np.zeros((npeaks,),dtype=np.float)
    
    pol = 0
    for k_i,l_i in itertools.product(*map(range,peakgrid.shape)):
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
    """Convert a peaks-table back to a peak grid.
    
    This will result in a grid ``k``x``l`` of peaks, where each element in the gird is a list of peak properties. Each peak property is a dictionary with keys ``'alpha','omega','variance','rms'``.
    
    :param ndarray table: A record array with columns ``k``, ``l``, :math:`\\alpha`, :math:`\omega`, power, and fit ``rms``.
    :param tuple shape: The shape of output grid, which should be the maximum ``k`` and ``l`` to be inserted.
    :return: ``peaks_grid, npeaks`` where the grid is as specified above, and ``npeaks`` is a grid with the number of peaks in each element stored in that element.
    
    Note that ``k`` and ``l`` are indicies, not spatial frequencies, and so are always between 0 and their respective maxima.
    
    This function is the inverse of :func:`peaks_to_table`.
    
    """
    peaks_grid = np.empty(shape,dtype=object)
    npeaks = np.zeros(shape,dtype=np.int)
    for k_i,l_i in itertools.product(*map(range,shape)):
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
    
def peaks_array_from_grid(peaks,npeaks=None):
    """The function turns a grid of peaks into a multidimensional array of peaks.
    
    The array will have shape ``(k,l,n,4)`` where ``n`` is the largest number of peaks in any ``k,l`` mode.
    
    :param ndarray peaks: The grid of peaks from which to draw items.
    :param ndarray npeaks: An array specifying the number of peaks at each ``k,l`` position. If ``None``, it will be calculated.
    :return: A 4-D grid of peak parameters. The dimensions are ``k,l,n,p`` where p is the parameter, stored as ``[alpha,omega,variance,rms]``.
    
    """
    if npeaks is None:
        npeaks = np.reshape([len(x) for x in peaks.flat],peaks.shape)
    peaks_grid = np.zeros(peaks.shape + (np.max(npeaks),4))
    for k,l in itertools.product(*map(range,peaks.shape)):
        if npeaks[k,l] > 0:
            peaks_grid[k,l,:npeaks[k,l],:] = np.array([ [peak["alpha"], peak["omega"], peak["variance"], peak["rms"] ] for peak in peaks[k,l]])
    return peaks_grid
    
def layers_to_table(layers):
    """Convert lists of layer dictionaries to table."""
    return lodtorec(layers, ["vx","vy","m"])
    
def layers_from_table(layers):
    """Convert a record array to a list of dictionaries."""
    return rectolod(layers)
    
def set_fmts_header_values(hdu,fmtstype,wcaotype=None):
    """Set the FMTS header values"""
    if wcaotype is None:
        wcaotype = "FMTS" + fmtstype
    hdu = set_wcao_header_values(hdu, wcaotype)
    hdu.header["FMTStype"] = (fmtstype, "FMTS File Type")
    hdu.header["FMTSvers"] = (1.0, "FMTS File Version")
    return hdu
    
def verify_fmts_header_values(hdu,fmtstype,wcaotype=None):
    """Verify the FMTS header values."""
    if wcaotype is None:
        wcaotype = "FMTS" + fmtstype
    verify_wcao_header_values(hdu, wcaotype)
    if hdu.header["FMTStype"] != fmtstype:
        raise ValueError("Mismatch FMTS type: got {:s}, expected {:s}".format(hdu.header["FMTStype"], fmtstype))
    if hdu.header["FMTSvers"] != 1.0:
        raise ValueError("FMTS Version Number Mismatch: got {:s} expected {:s}".format(hdu.header["FMTSvers"],1.0))
    return hdu

def save_periodogram(psd, rate):
    """Save the periodogram to a fits file.
    
    The primary HDU contains the full ``t,k,l`` periodogram. The secondary HDU contains the frequency scale for this data. The secondary HDU could be recreated using the ``rate`` keyword in the primary header. The periodogram is stored with four axes, so reconstruction the data can be done like this::
        
        data = fitsdata[0] + 1j * fitsdata[1]
        
    
    """
    from astropy.io import fits
    psd = np.array([np.real(psd),np.imag(psd)])
    HDU = fits.ImageHDU(psd)
    set_fmts_header_values(HDU,'periodogram')
    HDU.header['FMTSrate'] = rate
    return HDU
    
def load_periodogram(hdu):
    """Load the periodogram from a fits HDU.
    
    This function loads periodograms which were saved by :meth:`save_periodogram`.
    
    """
    verify_fmts_header_values(hdu,'periodogram')
    psd = hdu.data[0].copy() + 1j * hdu.data[1].copy()
    rate = np.copy(hdu.header['FMTSrate'])
    per_length = psd.shape[0]
    hz = np.mgrid[-1*per_length/2:per_length/2] / per_length * rate
    return psd, rate, hz
    
def save_peaks(peaks,npeaks):
    """
    Save found peaks to a table. The fits table is a simple way of storing the results from :func:`peaks_to_table`.
    """
    from astropy.io import fits
    hdu = fits.new_table(peaks_to_table(peaks,np.sum(npeaks)))
    set_fmts_header_values(hdu,'peaks')
    hdu.header['FMTSnfx'] = (peaks.shape[0],"Frequency Samples in x")
    hdu.header['FMTSnfy'] = (peaks.shape[1], "Frequency Samples in y")
    return hdu
    
def load_peaks(hdu):
    """Loads found peaks from a fits file saved in the format of :meth:`_save_peaks_to_table`."""
    verify_fmts_header_values(hdu,'peaks')
    nfx = int(hdu.header['FMTSnfx'])
    nfy = int(hdu.header['FMTSnfy'])
    return peaks_from_table(hdu.data,(nfx,nfy))
    

def set_f_metric_headers(hdu,fx,fy):
    """Set the appropriate header values for wind-velocity metric arrays."""
    import scipy.fftpack
    hdu.header["FMTSnuxf"] = (len(fx), "Number of x spatial frequency modes.")
    hdu.header["FMTSscxf"] = (1.0/np.mean(np.diff(scipy.fftpack.ifftshift(fx))), "Scaling for each x spatial mode.")
    hdu.header["FMTSnuyf"] = (len(fy), "Number of y spatial frequency modes.")
    hdu.header["FMTSscyf"] = (1.0/np.mean(np.diff(scipy.fftpack.ifftshift(fy))), "Scaling for each y spatial mode.")
    hdu.header["FMTSrecf"] = ("fftshift(fftfreq(FMTSnumf,FMTSscaf))","Code to reconstruct frequency vector.")
    return hdu
    
def read_f_metric_headers(hdu):
    """Read the appropriate header values for the frequency-wind-velocity metric arrays."""
    import scipy.fftpack
    d = float(hdu.header["FMTSscxf"])
    n = int(hdu.header["FMTSnuxf"])
    fx = scipy.fftpack.fftshift(scipy.fftpack.fftfreq(n,d))
    d = float(hdu.header["FMTSscyf"])
    n = int(hdu.header["FMTSnuyf"])
    fy = scipy.fftpack.fftshift(scipy.fftpack.fftfreq(n,d))
    return fx,fy
    
def save_fmts_map(wmap,vx,vy,fmtstype):
    """Saves the minimum amount of information to reconstruct a given map."""
    hdu = save_map(wmap,vx,vy,"FMTS"+fmtstype)
    return set_fmts_header_values(hdu,fmtstype)
    
def load_fmts_map(hdu,fmtstype,scale=True):
    """Load a map from an HDU"""
    verify_fmts_header_values(hdu,fmtstype)
    return load_map(hdu,scale=scale,wcaotype=None)
    
def save_fvmap(fvmap,fx,fy,vx,vy,fmtstype):
    """Save an fv map object."""
    from astropy.io import fits
    hdu = fits.ImageHDU(fvmap)
    set_fmts_header_values(hdu,fmtstype)
    set_v_metric_headers(hdu,vx,vy)
    set_f_metric_headers(hdu,fx,fy)
    return hdu
    
def load_fvmap(hdu,fmtstype,scale=True):
    """docstring for load_fvmap"""
    verify_fmts_header_values(hdu,fmtstype)
    data = hdu.data.copy()
    if scale:
        fx,fy = read_f_metric_headers(hdu)
        vx,vy = read_v_metric_headers(hdu)
        return data, fx, fy, vx, vy
    else:
        return data
    
def mi_fix_dtype(match_info,key):
    """Fix the data type for match info objects."""
    if match_info[key].dtype == np.bool:
        data = match_info[key].astype(np.uint8)
    elif match_info[key].dtype == np.int:
        data = match_info[key].astype(np.uint8)
    else:
        data = match_info[key]
    return data
    
    
def mi_save_metric(match_info,key,fmtstype):
    """`match_info` save metric."""
    return save_fmts_map(mi_fix_dtype(match_info,key),match_info['vv'],match_info['vv'],fmtstype)
    
def mi_save_fv_metric(match_info,key,fmtstype):
    """`match_info` save metric with f and v."""
    return save_fvmap(mi_fix_dtype(match_info,key),match_info['ff'],match_info['ff'],match_info['vv'],match_info['vv'],fmtstype)
    
def mi_save_simple(match_info,key,fmtstype):
    """Save a full-on metric"""
    from astropy.io import fits
    hdu = fits.ImageHDU(mi_fix_dtype(match_info,key))
    return set_fmts_header_values(hdu,fmtstype)
    
def get_match_info_pars():
    """Return the relevant dictionaries for match info parameters."""
    from pyshell.config import Configuration
    return Configuration.fromresource(__name__,'_fmts_io.yml')
    
    
def save_match_info(match_info):
    """Save all the data in the match info dictionary to a file."""
    from astropy.io import fits
    pars = get_match_info_pars()
    HDUs = []
    for key, value in match_info.iteritems():
        if key in pars:
            builder = getattr(sys.modules[__name__], pars[key]['builder'])
            HDU = builder(match_info, key, pars[key]['type'])
            HDU.header['FMTSkey'] = (key, "FMTS match_info dictionary key")
            HDU.header['FMTSdesc'] = (pars[key]['description'], "Description")
            HDU.update_ext_name(pars[key]['name'])
            HDUs.append(HDU)
    return HDUs
    
    
def load_match_info(HDUs):
    """Load the massive match info dictionary from a FITS file."""
    match_info = {}
    for HDU in HDUs:
        fmtstype = HDU.header['FMTSTYPE']
        verify_fmts_header_values(HDU,fmtstype)
        key = HDU.header["FMTSKEY"]
        match_info[key] = HDU.data.copy()
        if 'FMTSRECF' in HDU.header and 'ff' not in match_info:
            fx, fy = read_f_metric_headers(HDU)
            match_info["ff"] = fx
        if 'WCAORECV' in HDU.header and 'vv' not in match_info:
            vx, vy = read_v_metric_headers(HDU)
            match_info["vv"] = vx
    return match_info
    
        
def save_layer_info(layers):
    """Save the layer info to a FITS file."""
    from astropy.io import fits
    table = fits.new_table(layers_to_table(layers))
    set_fmts_header_values(table,'layers')
    return table
    
def load_layer_info(hdu):
    """Load layer information."""
    verify_fmts_header_values(hdu,'layers')
    return layers_from_table(hdu.data.copy())
    
    