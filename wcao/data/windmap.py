# -*- coding: utf-8 -*-
# 
#  windmap.py
#  aopy
#  
#  Created by Jaberwocky on 2013-07-15.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
"""
:mod:`wcao.data.windmap` - A generic windmap class for WCAO results.
====================================================================


"""

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)
import numpy as np

import datetime
import os.path

from .estimator import WCAOEstimate, set_wcao_header_values, verify_wcao_header_values

def set_v_metric_headers(hdu,vx,vy):
    """Set the appropriate header values for wind-velocity metric arrays."""
    hdu.header["WCAOmaxv"] = (np.max(vx), "Maximum searched x velocity")
    hdu.header["WCAOmixv"] = (np.min(vx), "Minimum searched x velocity")
    hdu.header["WCAOnuxv"] = (len(vx), "Number of x velocity gridpoints")
    hdu.header["WCAOmayv"] = (np.max(vy), "Maximum searched y velocity")
    hdu.header["WCAOmiyv"] = (np.min(vy), "Minimum searched y velocity")
    hdu.header["WCAOnuyv"] = (len(vy), "Number of y velocity gridpoints")
    hdu.header["WCAOrecv"] = ("np.linspace(WCAOMI?V,WCAOMA?V,WCAONU?V)","Psuedocode to reconstruct velocity grids.")
    return hdu
    
    
def read_v_metric_headers(hdu):
    """Read the appropriate header values for wind-velocity metric arrays."""
    vx = np.linspace(float(hdu.header["WCAOmixv"]),float(hdu.header["WCAOmaxv"]),int(hdu.header["WCAOnuxv"]))
    vy = np.linspace(float(hdu.header["WCAOmiyv"]),float(hdu.header["WCAOmayv"]),int(hdu.header["WCAOnuyv"]))
    return vx,vy
    
    
def save_map(wmap,vx,vy,wcaotype):
    """Saves the minimum amount of information to reconstruct a given map."""
    from astropy.io import fits
    hdu = fits.ImageHDU(wmap)
    set_wcao_header_values(hdu,wcaotype)
    set_v_metric_headers(hdu,vx,vy)
    return hdu

def load_map(hdu,wcaotype=None,scale=True):
    """Load a map from an HDU"""
    verify_wcao_header_values(hdu,wcaotype)
    wmap = hdu.data.copy()
    if scale:
        vx,vy = read_v_metric_headers(hdu)
        return wmap,vx,vy
    else:
        return wmap


class WCAOmap(WCAOEstimate):
    """A generic WCAO estimate as a map."""
    def __init__(self, arg):
        super(WCAOmap, self).__init__()
        self.arg = arg
        