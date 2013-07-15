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

import itertools

import numpy as np

from aopy.util.math import lodtorec, rectolod

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
    
    