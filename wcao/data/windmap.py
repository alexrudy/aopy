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
import warnings
import os.path

from astropy.units import u

from .estimator import WCAOEstimate

from aopy.util.units import ensure_quantity


class WCAOMap(WCAOEstimate):
    """A generic WCAO estimate as a map."""
    
    def init_data(self,data=None, vx=None, vy=None, layers=None):
        """Data initialization."""
        if isinstance(data, np.ndarray):
            if data.ndim == 2:
                self.map = data
            else:
                raise ValueError("{}: Expected map with ndim=2, got {:d}".format(
                    self, data.ndim
                ))
        elif data is not None:
            raise ValueError("{}: Expected map of type {}, got {}".format(
                self, np.ndarray, type(data)
            ))
        else:
            if not all(map(lambda i: i is None,[vx,vy,layers])):
                warnings.warn("{}:Ignoring metadata because map==None".format(self))
            return
        
        if vx is None:
            self.vx = np.arange(self.map.shape[0])
        else:
            self.vx = ensure_quantity(vx, u.m/u.s)
        if vy is None:
            self.vy = np.arange(self.map.shape[1])
        else:
            self.vy = ensure_quantity(vy, u.m/u.s)
        self.layers = layers or []
    
    @property
    def extent(self):
        """The extent array for this map."""
        return [np.min(self.vx),np.max(self.vx),np.min(self.vy),np.max(self.vy)]
        
    @property
    def data(self):
        """Data accessor."""
        return self.map
        