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

from .estimator import WCAOEstimate


class WCAOMap(WCAOEstimate):
    """A generic WCAO estimate as a map."""
    
    def _init_data(self,data):
        """Data initialization."""
        if isinstance(data, np.ndarray):
            if data.ndim == 2:
                self.map = data
                self.vx = np.arange(self.map.shape[0])
                self.vy = np.arange(self.map.shape[1])
            else:
                raise ValueError("{}: Expected map with ndim=2, got {:d}".format(
                    self, data.ndim
                ))
        elif isinstance(data, tuple):
            if len(data) == 3:
                self.map, self.vx, self.vy = data
            elif len(data) == 4:
                self.map, self.vx, self.vy, self.layers = data
            else:
                raise ValueError("{}: Data has the wrong number of elements: {:d}.".format(
                    self, len(data)
                ))
        elif isinstance(data, dict):
            self.map = data["map"]
            self.vx = data.get("vx", np.arange(self.map.shape[0]))
            self.vy = data.get("vy", np.arange(self.map.shape[1]))
            self.layers = data.get("layers", [])
    
    def save(self):
        """Save a file"""
        from ..io.fitsmaps import MapIO
        writer = MapIO(self.fitsname.rstrip(".fits"), self)
        writer.write()
    
    def load(self):
        """Load a file"""
        from ..io.fitsmaps import MapIO
        reader = MapIO(self.fitsname.rstrip(".fits"), self)
        reader.read()
        
    
    @property
    def extent(self):
        """The extent array for this map."""
        return [np.min(self.vx),np.max(self.vx),np.min(self.vy),np.max(self.vy)]
        
    
        