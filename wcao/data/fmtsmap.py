# -*- coding: utf-8 -*-
# 
#  fmtsmap.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-31.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)
import numpy as np

from .estimator import WCAOEstimate

class WCAOFMTSMap(WCAOEstimate):
    """docstring for WCAOFMTSMap"""
    def __init__(self, *args, **kwargs):
        super(WCAOFMTSMap, self).__init__(*args, **kwargs)
    
    def _init_data(self,data):
        """Initialize the map data"""
        if data is None:
            return
        data = np.array(data)
        if data.ndim != 2:
            raise ValueError("{0:s}-type data should have 2 dimensions: (vx,vy). data.ndim={1.ndim:d}".format(self._arraytype,data))
        self._data = data
        
    def display_metric(self,ax,title=None,**kwargs):
        """Display the metric"""
        
        kwargs.setdefault('interpolation','nearest')
        kwargs.setdefault('vmin',0)
        kwargs.setdefault('vmax',1)
        image = ax.imshow(self._data,)