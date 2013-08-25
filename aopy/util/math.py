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
----------------------------------------------

These are various mathematical algorithms used in :mod:`aopy`. They are implemented here to ensure that their implementation is consistent across :mod:`aopy`.


.. _util.math.aperture:

Phase and Aperture Functions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. autofunction::
    depiston
    
.. autofunction::
    detilt

.. autofunction::
    edgemask
    
Other Mathematical Functions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

"""
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)
                  
import functools, contextlib
import numpy as np

def complexmp(mag, phase):
    """docstring for complexmp"""
    return mag * np.cos(phase) + mag * 1j * np.sin(phase)

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
    
def fast_shift(source, shift, order=1, mode='wrap', prefilter=True, shape=None, pad=1):
    """Do a fast shift, clipping to match output shape.
    
    This shift method currently is limited to 2-dimensional objects.
    
    :param source: The source array. This item **must** be an :class:`numpy.ndarray`.
    :param shift: The shift vector.
    :param int order: The spline interpolation order, ``1 <= order <= 5``.
    :param mode: What to do at the borders. See the documentation for :func:`scipy.ndimage.interpolation.shift`, but note that technically, the ``wrap`` mode is broken. That won't matter so long as `pad` is more than 0.
    :param bool prefilter: Whether to apply a spline interpolation prefilter, if it is required. This is required for spline interpolation with order larger than 1. However, doing the filter once on the source array may be more efficient than individually filtering data.
    :param shape: The desired output shape, after the shift. The output shape will start from the ``0,0`` index after the shift.
    :param int pad: The padding used around array edges. Padding allows this method to fix the broken `wrap` mode in :mod:`scipy.ndimage`.
    
    This is a wrapper around :func:`scipy.ndimage.interpolation.shift` which speeds up shifting if the desired output shape is much smaller than the total array shape. It works by only undertaking the non-integer part of the shift in scipy, and using indexing tricks to collect only the target area and a 1-element border.
    """
    import scipy.ndimage.interpolation
    shift = np.array(shift)
    if shape is None:
        shape = source.shape
    _shape = tuple(np.array(shape) + 2*pad)
    _inds = np.indices(_shape)
    _floor = np.floor(shift)
    _shift = (shift - _floor)
    _start = -1 * _floor - pad    
    _inds += _start[:,np.newaxis,np.newaxis]
    r_inds = np.ravel_multi_index(_inds, source.shape, mode='wrap')
    shifted = source.flat[r_inds]
    if (_shift != 0.0).any():
        interped = scipy.ndimage.interpolation.shift(
            input = shifted,
            shift = -1*_shift,
            order = order,
            mode = mode,
            prefilter = prefilter,
        )
    else:
        interped = shifted
    x,y = np.array(shape) + pad
    return interped[pad:x,pad:y]

    
def slow_shift(input, shift, order=1, mode='wrap', prefilter=True, output_shape=None):
    """Do a full shift using :func:`scipy.ndimage.interpolation.shift`.
    
    .. warning:: Due to <https://github.com/scipy/scipy/issues/2640?source=cc>, when this shift wraps, it produces an error!"""
    import scipy.ndimage.interpolation
    interped = scipy.ndimage.interpolation.shift(
        input = input,
        shift = shift,
        order = order,
        mode = mode,
        prefilter = prefilter,
    )
    x,y = np.indices(output_shape)
    return interped[x,y]
    
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

@contextlib.contextmanager
def ignoredivide():
    """A context manager for ignoring division"""
    errsettings = np.seterr(all='ignore')
    yield
    np.seterr(**errsettings)
    
    
    
        