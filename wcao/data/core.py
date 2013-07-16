# -*- coding: utf-8 -*-
# 
#  core.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-01.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
"""
:mod:`wcao.data.core` – WCAO Data Structures
============================================

.. autoclass::
    WCAOCase
    :members:

"""

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import abc
import os, os.path
import warnings

import numpy as np

from astropy.io import fits

import pyshell
from pyshell.config import StructuredConfiguration, DottedConfiguration

from aopy.aperture import Aperture
from aopy.util.basic import ConsoleContext

from wcao.data.telemetry import WCAOTelemetry



class WCAOCase(ConsoleContext):
    """A representation of a specific WCAO data case."""
    
    __metaclass__ = abc.ABCMeta
    
    def __init__(self, instrument, casename, configuration):
        super(WCAOCase, self).__init__()
        self._config = StructuredConfiguration.make(configuration)
        self._config.renest(DottedConfiguration)
        self.instrument = instrument
        self.casename = casename
        self.results = {}
        self.telemetry = WCAOTelemetry(self)
        
    def __str__(self):
        """Make a pretty string format of the contents of this WCAO case."""
        lines = [ "WCAOCase: {:s}".format(self.name) ]
        
        if self.telemetry:
            lines += [ "Telemetry: ", " " + str(self.telemetry) ]
        
        if len(self.results) > 0:
            lines += [ "Estimator Results:" ]
            lines += [ " " + str(result) for result in self.results.values() ]
        
        return "\n".join(lines)
        
    @property
    def name(self):
        """Return the full name"""
        return "{0.instrument:s}-{0.casename:s}".format(self)
        
    @property
    def config(self):
        """Instrument specific configuration"""
        return self._config
        
    @property
    def inst_config(self):
        """Instrument specific configuration."""
        return self._config[".".join(["Telemetry",self.instrument])]
        
    @property
    def rate(self):
        """AO system control rate"""
        return self.inst_config["system.rate"]
    
    @property
    def subapd(self):
        """Subaperture Diameter"""
        return self.inst_config["system.d"]
    
    @property
    def data_format(self):
        """Data format specifier"""
        return self.inst_config["data.format"]
    
    def addresult(self,data,klass,dtype):
        """Add a result for this case. The data type is used to identify this specific result, and trace its origins to an estimator."""
        self.results[dtype] = klass(self,data,dtype)
    
        
