# -*- coding: utf-8 -*-
# 
#  core.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-01.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
"""
Core WCAO Data Structures
=========================

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
        self._config.dn = StructuredConfiguration
        self.instrument = instrument
        self.casename = casename
        self.results = {}
        self.telemetry = WCAOTelemetry(self)
        
    @property
    def name(self):
        """Return the full name"""
        return "{0.instrument:s}-{0.casename:s}".format(self)
        
    @property
    def config(self):
        """Instrument specific configuration"""
        return self._config[self.instrument]
        
    @property
    def rate(self):
        """AO system control rate"""
        return self.config["system.rate"]
    
    @property
    def subapd(self):
        """Subaperture Diameter"""
        return self.config["system.d"]
    
    @property
    def data_format(self):
        """Data format specifier"""
        return self.config["data.format"]
    
    def addresult(self,data,klass,dtype):
        """Add a result"""
        self.results[dtype] = klass(self,data,dtype)
    
        
