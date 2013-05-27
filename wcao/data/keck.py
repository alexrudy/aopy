# -*- coding: utf-8 -*-
# 
#  keck.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-06.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
"""
:mod:`data.keck <wcao.data.keck>` Telemetry Data from the Keck Telescope
========================================================================
"""

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np

from pkg_resources import resource_stream
keck_aper = (np.loadtxt(resource_stream(__name__,'act_map.txt')) != 0)
keck_sub  = (np.loadtxt(resource_stream(__name__,'sub_ap_map.txt')) != 0)

def disp2d(data):
    """Map a data set into the Keck Pupil mapping.
    
    :param numpy.ndarray data: The data to be mapped. The mapping will be inferred.
    :returns: (:class:`~numpy.ndarray`) the data filled into an apropriate aperture
    
    ported from ``disp2d.pro`` by Marcos
    """
    
    
    if data.size == 304:
        output = np.zeros((20,20))
        output[keck_sub] = data
    elif data.size == 608:
        ix = np.arange(304) * 2.0
        x = data[ix]
        y = data[ix+1.0]
        output = np.zeros((20,20,2))
        output[keck_sub,...,0] = x
        output[keck_sub,...,1] = y
    elif data.size == 349:
        output = np.zeros((21,21))
        output[keck_aper] = data
    elif data.size == 352:
        output = np.zeros((21,21))
        output[keck_aper] = data[:349]
    elif data.size == 1600:
        output = np.reshape(data,(40,40))
    elif data.size == 6400:
        output = np.reshape(data,(80,80))
    return output
    

"""
The IDL Code ported by transfac is::
    
    ;;; This is the influence function filter of keck's DM.
    ;;; taken from telemetry_analysis_07/get_dm_transfer_function.pro
    w1 = 2
    w2 = -1
    sig1 = 0.54
    sig2 = 0.85
    ;    kfac = 0.47
    kfac = 1. ;;; already folded in the get_processed_data_keck
    m = 8.
    myx = rebin(findgen(n*m) - n*m/2, n*m, n*m)*1./m
    myy = transpose(myx)

    influence_function = kfac*(w1/(2*!pi*sig1^2)*exp(-0.5*(myx^2 + myy^2)/sig1^2) + $
                             w2/(2*!pi*sig2^2)*exp(-0.5*(myx^2 + myy^2)/sig2^2))

    bigtf = shift(real_part(fft(shift(influence_function, n*M/2, n*m/2)))*n^2, n*M/2, n*m/2)
    tf = shift(bigtf[n*m/2-n/2: n*m/2+n/2-1, n*m/2-n/2: n*m/2+n/2-1], n/2, n/2)
    dmtrans_mulfac = abs(tf)^2
    
  
"""

def transfac():
    """Keck Transfer Function. See the IDL Code above to understand this data."""
    import scipy.fftpack
    w1 = 2.0
    w2 = -1.0
    sig1 = 0.54
    sig2 = 0.85
    kfac = 1.0
    m = 8
    n = 26
    
    mn = n * m
    mns = mn // 2
    
    x,y = np.mgrid[-1*mns:mns,-1*mns:mns]
    x,y = x.astype(np.float)/m, y.astype(np.float)/m
    influence_function = kfac * (w1 / (2 * np.pi * sig1**2.0) * np.exp(-0.5 * (x**2.0 + y**2.0)/sig1**2.0)) + (w2 / (2 * np.pi * sig2**2.0) * np.exp(-0.5 * (x**2.0 + y**2.0)/sig2**2.0))
    bigtf = scipy.fftpack.ifftshift(np.real(scipy.fftpack.ifft2(scipy.fftpack.fftshift(influence_function)))) * n ** 2.0
    tf = bigtf[n*m/2-n/2: n*m/2+n/2, n*m/2-n/2: n*m/2+n/2]
    tf = np.roll(np.roll(tf,int(n//2),axis=0),int(n//2),axis=1)
    return np.abs(tf)**2.0
    
    
    

    