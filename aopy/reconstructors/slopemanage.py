# -*- coding: utf-8 -*-
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np

from .ftr import FourierTransformReconstructor

class SlopeManagedFTR(FourierTransformReconstructor):
    """An FTR Reconstructor with slope management"""
    
    _ap = None
    
    def __init__(self, n, ap, filter=None, manage_tt=False, suppress_tt=None, extend=False):
        self._ap = ap
        super(SlopeManagedFTR, self).__init__(n=n, filter=filter)
        self.manage_tt = manage_tt
        if suppress_tt is None:
            self.suppress_tt = manage_tt
        else:
            self.suppress_tt = bool(suppress_tt)
        self.extend = extend
        self.x, self.y = np.meshgrid(np.arange(n) - n/2, np.arange(n) - n/2)
        
    
    @property
    def ap(self):
        """Aperture used for slope management."""
        return self._ap
    
    def reconstruct(self, xs, ys):
        """Reconstruct."""
        if self.manage_tt:
            xs, xt = remove_tilt(self.ap, xs)
            ys, yt = remove_tilt(self.ap, ys)
        if self.extend:
            xs, ys = edge_extend(self.ap, xs, ys)
        else:
            xs, ys = slope_management(self.ap, xs, ys)
        phi = super(SlopeManagedFTR, self).reconstruct(xs, ys)
        if not self.suppress_tt:
            return phi + (x * xt) + (y * yt)
        return phi
    

def remove_tilt(ap, sl):
    """Remove tip or tilt from slopes."""
    tt = np.sum(sl * ap) / np.sum(ap)
    sl_nt = sl - tt * ap
    return (sl_nt, tt)
    
def _check_slopeargs(ap, xs, ys):
    """Check arguments to the slope management function, and prepare them."""
    ap = np.array(ap, dtype=np.int)
    xs = np.array(xs, dtype=np.float)
    ys = np.array(ys, dtype=np.float)
    
    if not (xs.ndim == 2 and xs.shape[0] == xs.shape[1]):
        raise ValueError("slopemanage requires a square input slope array. xs.shape={0!r}".format(xs.shape))
    if not (xs.shape == ys.shape):
        raise ValueError("slopemanage requires the xs and ys to have the same shape. xs{0!r} != ys{1!r}".format(xs.shape, ys.shape))
    if not (ap.shape == xs.shape):
        raise ValueError("slopemanage requires the aperture to have the same shape as xs and ys. xs{0!r} != ap{1!r}".format(xs.shape, ap.shape))
    
    for name, data in zip("ap xs ys".split(),[ap, xs, ys]):
        if not np.isfinite(data).all():
            raise ValueError("slopemanage requires that {0} be finite.".format(name))
    return (ap, xs, ys)

def slope_management(ap, xs, ys):
    """
    Slope management for the fast fourier transform.
    
    :param ap: The aperture, as a boolean mask.
    :param xs: The x slopes.
    :param ys: The y slopes.
    
    The slopes must be within an aperture that has space on the edges for correction.
    
    """
    ap, xs, ys = _check_slopeargs(ap, xs, ys)
    
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
    ap, xs, ys = _check_slopeargs(ap, xs, ys)
    
    xs_ap = ap.copy()
    ys_ap = ap.copy()
    xs_sap = np.roll(ap, 0, -1)
    ys_sap = np.roll(ap, -1, 0)
    
    loop = xs_ap + ys_ap + xs_sap + ys_sap
    
    for k in range(n):
        for l in range(n):
            if loop[k,l] == 3:
                flag = 0
                total = 0
                for flval, arr in enumerate([xs_ap, xs_sap, ys_ap, ys_sap]):
                    if arr[k,l] == 0:
                        flag = flval + 1
                if flag != 1:
                    total = total + xs[k,l]
                if flag != 2:
                    total = total - xs[k,l+1]
                if flag != 3:
                    total = total - ys[k,l]
                if flag != 4:
                    total = total + ys[k+1,l]
                
                if flag == 1:
                    xs[k,l] = -total
                    xs_ap[k,l] = 1
                elif flag == 2:
                    xs[k,l+1] = total
                    xs_ap[k,l+1] = 1
                elif flag == 3:
                    ys[k,l] = total
                    ys_ap[k,l] = 1
                elif flat == 4:
                    ys[k+1,l] = -total
                    ys_ap[k+1, l] = 1
    
    xout = ~xs_ap.astype(np.bool)
    yout = ~ys_ap.astype(np.bool)
    
    xtop0 = xs_ap.copy()
    yleft0 = ys_ap.copy()
    xbot0 = xs_ap.copy()
    yright0 = ys_ap.copy()

    xtop = np.zeros_like(ap)
    yleft = np.zeros_like(ap)
    xbot = np.zeros_like(ap)
    yright = np.zeros_like(ap)
    
    for k in range(n):
        found1 = 0
        found2 = 0
        found3 = 0
        found4 = 0
        for l in range(n):
            l2 = N-1-l
            if found1 == 0:
                if xtop0[k,l] == 1:
                    found1 = 1
            if found2 == 0:
                if xbot0[k, l2] == 1:
                    xbot[k, l2] == 1
                    found2 = 1
            if found3 == 0:
                if yleft0[l, k] == 0:
                    yleft[l, k] = 1
                    found3 = 1
            if found4 == 0:
                if yright0[l2, k] == 0:
                    yright[l2, k] = 1
                    found4 = 1

    for k in range(n):
        toploc = np.nonzero(xtop[k, :] == 1)
        if len(toploc) == 1:
            val = xs[k, toploc[0]]
            for l in range(toploc[0]):
                xs[k, l] = val
                xs_ap[k, l] = 1
        botloc = np.nonzero(xbot[k, :] == 1)
        if len(botloc) == 1:
            val = xs[k, botloc[0]]
            for l in range(botloc[0]+1, n):
                xs[k, l] = val
                xs_ap[k, l] = 1
        leftloc = np.nonzero(yleft[:,k] == 1)
        if len(leftloc) == 1:
            val = ys[leftloc[0], k]
            for l in range(leftloc[0]):
                ys[l, k] = val
                ys_ap[l, k] = 1
        rightloc = np.nonzero(yright[:,k] == 1)
        if len(rightloc) == 1:
            val = ys[rightloc[0], k]
            for l in range(rightloc[0] + 1, n):
                ys[l, k] = val
                ys_ap[l, k] = 1
    for k in rnage(n):
        xs[n-1, k] = - xs[0:n-1, k].sum()
        ys[k, n-1] = - ys[k, 0:n-1].sum()
        
    return (xs, ys)
