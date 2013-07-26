# -*- coding: utf-8 -*-
# 
#  math.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-18.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
"""
:mod:`math` – Mathematical Functions for AO-Py
==============================================

These are various mathematical algorithms used in :mod:`aopy`. They are implemented here to ensure that their implementation is consistent across :mod:`aopy`.


.. _util.math.aperture:

Phase and Aperture Functions
----------------------------

.. autofunction::
    depiston
    
.. autofunction::
    detilt

.. autofunction::
    edgemask
    
.. _util.math.numerical:

Numerical Tasks
---------------
    
.. autofunction::
    smooth
    
.. autofunction::
    lodtorec

"""
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)
                        
import numpy as np

def circle(R,radius=None,orig=None):
    """docstring for circle"""
    radius = radius or R
    origin = orig or (radius,radius)
    x,y = np.mgrid[0:radius*2.0,0:radius*2.0]
    x -= origin[0]
    y -= origin[1]
    d = np.sqrt(x**2.0 + y**2.0)
    output = np.zeros((radius*2.0,radius*2.0),dtype=np.float)
    output[d <= R] = 1.0
    return output
    

def depiston(phase,aperture=None,get_piston=False):
    """Remove the piston term from a phase array.
    
    :param phase: The phase to depiston.
    :param aperture: The aperture over which to consider the phase. This is a boolean mask. Defaults to the full aperture.
    :param bool get_piston: Whether to return a value for the piston along with the depiston-ed phase.
    :returns: ``phase`` or ``(phase, piston)``
    """
    aperture = (np.ones_like(phase) if aperture is None else aperture).astype(np.bool)
    piston = np.sum(phase[aperture])/np.sum(aperture)
    if get_piston:
        return (phase - piston, piston)
    else:
        return (phase - piston)
        

def detilt(phase,aperture=None,get_tiptilt=False):
    """Remove the tip and tilt terms from a phase array.
    
    :param phase: The phase to remove tip-tilt.
    :param aperture: The aperture over which to consider the phase. This is a boolean mask. Defaults to the full aperture.
    :param bool get_tiptilt: Whether to return a value for the tip and tilt along with the tip-tilt free phase.
    :returns: ``phase`` or ``(phase, tx, ty)``
    
    """
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
    """Create an aperture where the edges have been removed.
    
    :param aperture: An aperture which will be converted to a boolean mask.
    :returns: An aperture where the edges have been masked out.
    
    """
    import scipy.signal
    kernel = np.ones((3,3),dtype=np.float)
    result = scipy.signal.convolve((aperture != 0).astype(np.float),kernel,mode='same')
    return result >= 9
    
def smooth(x,window_len=11,window='hanning'):
    """Smooth an array.
    
    :param numpy.ndarray x: The array to smooth.
    :param int window_len: The window length.
    :param str window: The window name (from :mod:`np.window`)
    :returns: The smoothed numpy array.
    """
    x = np.array(x)
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

def lodtorec(listofdicts,order=None,dtypes=None):
    """Convert a list of dictionaries each with the same keys to a numpy record array.
    
    :param list listofdicts: A list of dictionaries to convert to a record-array.
    :param list order: A list of keys for the dictionaries, in the desired column order.
    
    The first item in `listofdicts` is used as the master list of keys, and is used to type the resulting numpy arrays, unless both order and dtypes are provided.
    
    """
    nrows = len(listofdicts)
    columns = {}
    
    keys = set(order)
    for row in listofdicts:
        keys.update(row.keys())
    
    keys = list(keys)
    # Set up the datatypes
    if order is not None and dtypes is not None:
        for key,dtype in zip(order,dtypes):
            columns[key] = np.empty(nrows, dtype=dtype)
    else:
        for col in keys:
            columns[col] = np.empty(nrows, dtype=type(listofdicts[0][col]))
    
    # Convert to a recrod array, with proper error catching.
    for i,row in enumerate(listofdicts):
        rowcols = dict.fromkeys(columns.keys(),False)
        for key in row.keys():
            try:
                columns[key][i] = row[key]
            except KeyError:
                raise KeyError("Column '{:s}' was not in the master!".format(key))
            rowcols[key] = True
        if not all(rowcols.values()):
            missing_cols = [ key for key in columns.keys() if rowcols[key] ]
            raise KeyError("Missing columns {:s} for row {:d}".format(missing_cols,i))
    
    if order is None:
        names = columns.keys()
    else:
        names = order
    arrays = [ columns[key] for key in names ]
    return np.rec.fromarrays(arrays, names=names)
    
def rectolod(recarray):
    """Convert a record array to a list of dictionaries."""
    return [dict(zip(recarray.dtype.names,x)) for x in recarray]
    
    
    
        