# -*- coding: utf-8 -*-
# 
#  slopemanage.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-08-09.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
"""
:mod:`slopemanage` – Slope aperture truncation
==============================================

"""


from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np

def slope_management(ap, xs, ys):
    """
    Slope management for the fast fourier transform.
    
    :param ap: The aperture, as a boolean mask.
    :param xs: The x slopes.
    :param ys: The y slopes.
    
    The slopes must be within an aperture that has space on the edges for correction.
    
    """
    
    ap = np.array(ap).astype(np.int)
    xs = np.array(xs)
    ys = np.array(ys)
    
    if not (xs.ndim == 2 and xs.shape[0] == xs.shape[1]):
        raise ValueError("slopemanage requires a square input slope array. xs.shape={!r}".format(xs.shape))
    if not (xs.shape == ys.shape):
        raise ValueError("slopemanage requires the xs and ys to have the same shape. xs{!r} != ys{!r}".format(xs.shape, ys.shape))
    if not (ap.shape == xs.shape):
        raise ValueError("slopemanage requires the aperture to have the same shape as xs and ys. xs{!r} != ap{!r}".format(xs.shape, ap.shape))
    
    n = xs.shape[0]
    
    xs_s = xs * ap
    ys_s = ys * ap
    
    xs_c = np.copy(xs_s)
    ys_c = np.copy(ys_s)
    
    ysr_sum = np.sum(ys_s, axis=0)
    apr_sum = np.sum(ap, axis=0)
    
    xsc_sum = np.sum(xs_s, axis=1)
    apc_sum = np.sum(ap, axis=1)
    
    for j in range(n):
        if apr_sum[j] != 0:
            loc = np.where(ap[:,j] != 0)[0]
            left = loc[0]
            right = loc[-1]
            
            if left == 0:
                raise ValueError("Not enough space to edge correct, row {j} ends at k={k}".format(j=j, k=0))
            if right == n:
                raise ValueError("Not enough space to edge correct, row {j} ends at k={k}".format(j=j, k=n))
            
            ys_c[left-1, j] = - 0.5 * ysr_sum[j]
            ys_c[right+1, j] = -0.5 * ysr_sum[j]
        
        if apc_sum[j] != 0:
            loc = np.where(ap[j,:] != 0)[0]
            bottom = loc[0]
            top = loc[-1]
            
            if bottom == 0:
                raise ValueError("Not enough space to edge correct, column {j} ends at k={k}".format(j=j, k=0))
            if top == n:
                raise ValueError("Not enough space to edge correct, column {j} ends at k={k}".format(j=j, k=n))
            
            xs_c[j, bottom-1] = -0.5 * xsc_sum[j]
            xs_c[j, top+1]    = -0.5 * xsc_sum[j]
            
    return (xs_c, ys_c)
    
    
def edge_extend(ap, xs, ys):
    """
    Edge Extension for the fast fourier transform.
    
    :param ap: The aperture, as a boolean mask.
    :param xs: The x slopes.
    :param ys: The y slopes.
    """
    
    for k in range(n):
        for l in range(n):
            if loop[k,l] == 3:
                flag = 0
                total = 0
                for flval, arr in enumerate([xs_ap, xs_sap, ys_ap, ys_sap]):
                    if arr[k,l] == 0:
                        flag = flval + 1
                    elif flval == 0:
                        total = total + xs[k,l]
                    elif flval == 1:
                        total = total + xs[k,l+1]
                    elif flval == 2:
                        total = total + ys[k,l]
                    elif flval == 3:
                        total = total + ys[k+1,l]
