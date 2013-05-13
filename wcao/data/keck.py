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

def disp2d(data):
    """Map a data set into the Keck Pupil mapping.
    
    :param numpy.ndarray data: The data to be mapped. The mapping will be inferred.
    :returns: (:class:`~numpy.ndarray`) the data filled into an apropriate aperture
    
    ported from ``disp2d.pro`` by Marcos
    """
    from pkg_resources import resource_stream
    keck_aper = (np.loadtxt(resource_stream(__name__,'act_map.txt')) != 0)
    keck_sub  = (np.loadtxt(resource_stream(__name__,'sub_ap_map.txt')) != 0)
    
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

    