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
        elif isinstance(data, tuple):
            if len(data) == 3:
                self.map, self.vx, self.vy = data
    
    def save(self):
        """Save a file"""
        from ..io.fitsmaps import MapWriter
        writer = MapWriter(self.fitsname.rstrip(".fits"), self)
        writer.write()
    
    def load(self):
        """Load a file"""
        from ..io.fitsmaps import MapReader
        reader = MapReader(self.fitsname.rstrip(".fits"), self)
        reader.read()
        
    
    @property
    def extent(self):
        """The extent array for this map."""
        return [np.min(self.vx),np.max(self.vx),np.min(self.vy),np.max(self.vy)]
        
    
        