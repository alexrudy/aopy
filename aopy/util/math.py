# -*- coding: utf-8 -*-
# 
#  math.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-18.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
"""
Basic Math Utiltiy Functions for AO-Py
"""
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)
                        
import numpy as np


def depiston(phase,aperture=None,get_piston=False):
    """docstring for depiston"""
    aperture = (np.ones_like(phase) if aperture is None else aperture).astype(np.bool)
    piston = np.sum(phase[aperture])/np.sum(aperture)
    if get_piston:
        return (phase - piston, piston)
    else:
        return (phase - piston)
        

def detilt(phase,aperture=None,get_tiptilt=False):
    """docstring for detilt"""
    aperture = np.ones_like(phase) if aperture is None else aperture
    n,m = phase.shape[:2]
    x,y = np.mgrid[-n//2,n//2,-m//2,m//2]
    
    x -= np.sum(x * aperture)/np.sum(x)
    y -= np.sum(y * aperture)/np.sum(y)
    
    tx = np.sum(phase * x * aperture)/np.sum(x * x * aperture)
    ty = np.sum(phase * y * aperture)/np.sum(y * y * aperture)
    
    phase_dt = phase - tx * x - ty * y
    
    if get_tiptilt:
        return (phase_dt, tx, ty)
    else:
        return phase_dt
        
def edgemask(aperture):
    """Return an aperture where the edges have been removed."""
    import scipy.signal
    kernel = np.ones((3,3))
    result = scipy.signal.convolve(aperture,kernel,mode='same')
    return result >= 9
    
def smooth(x,window_len=11,window='hanning'):
        if x.ndim != 1:
                raise ValueError, "smooth only accepts 1 dimension arrays."
        if x.size < window_len:
                raise ValueError, "Input vector needs to be bigger than window size."
        if window_len<3:
                return x
        if not window in ['flat', 'hanning', 'hamming', 'bartlett', 'blackman']:
                raise ValueError, "Window is on of 'flat', 'hanning', 'hamming', 'bartlett', 'blackman'"
        s=np.r_[2*x[0]-x[window_len-1::-1],x,2*x[-1]-x[-1:-window_len:-1]]
        if window == 'flat': #moving average
                w=np.ones(window_len,'d')
        else:  
                w=getattr(np,window)(window_len)
        y=np.convolve(w/w.sum(),s,mode='same')
        return y[window_len:-window_len+1]

    
        