# -*- coding: utf-8 -*-
#
#  core.py
#  aopy
#
#  Created by Alexander Rudy on 2013-05-01.
#  Copyright 2013 Alexander Rudy. All rights reserved.
#
"""
:mod:`wcao.data.case` – WCAO Data Structures
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
import collections

import numpy as np

from astropy.io import fits

import pyshell
import pyshell.loggers
from pyshell.config import StructuredConfiguration

from aopy.aperture import Aperture
from aopy.util.basic import ConsoleContext

from wcao.data.telemetry import WCAOTelemetry
from wcao.io.filenames import Filename



class WCAOCase(ConsoleContext):
    """A representation of a specific WCAO data case."""
    
    __metaclass__ = abc.ABCMeta
    
    def __init__(self, instrument, casename, configuration=None):
        super(WCAOCase, self).__init__()
        self.log = pyshell.getLogger('wcao')
        self._config = StructuredConfiguration.create(
            module=__name__,
            cfg=configuration,
            defaultcfg="wcao.yml",
            supercfg=[('wcao.data','telemetry.yml'),('wcao','logging.yml')])
        pyshell.loggers.configure_logging(self._config)
        
        
        self.instrument = instrument
        self.casename = casename
        self.results = collections.OrderedDict()
        self.telemetries = collections.OrderedDict()
        self.telemetry = WCAOTelemetry(self)
        
        if ".".join(["Telemetry",self.instrument]) not in self.config:
            raise Exception("Unknown instrument '{:s}'".format(self.instrument))
        if ".".join(["Telemetry",self.instrument,"data","cases",self.casename]) not in self.config:
            raise Exception("Unknown casename '{:s}' for instrument '{:s}'".format(self.casename,self.instrument))
        
    
    def __repr__(self):
        """Representation"""
        return "<{0.__class__.__name__}: {0.name}>".format(self)
    
    def __repr_pretty__(self, p, cycle):
        """Make a pretty string format of the contents of this WCAO case."""
        p.text("WCAOCase: {:s}".format(self.name))
        if self.telemetries:
            with p.group(2, 'Telemetry:',''):
                for telemetry in self.telemetries.values()
                    p.pretty(telemetry)
        
        if self.results:
            with p.group(2, 'Estimator Results:',''):
                for result in self.results.values()
                    p.pretty(result)
        
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
    
    def addresult(self,data,klass,dtype):
        """Add a result for this case. The data type is used to identify this specific result, and trace its origins to an estimator."""
        self.results[dtype] = klass(self,data,dtype)

class WCAOData(object):
    """A base type for generic WCAO data objects."""
    
    def __init__(self, case):
        if not isinstance(case, WCAOCase):
            raise TypeError("{}: 'case' must be an instance of {}, got {}".format(
                self, WCAOCase.__name__, type(case)
            ))
        self.case = case
        self._config = self.case.config
        self.log = pyshell.getLogger(__name__)
        
    @property
    def config(self):
        """The configuration!"""
        return self._config
    
    @property
    def instrument(self):
        """Passthrough to case's instrument"""
        return self.case.instrument
    
    @property
    def name(self):
        """Passthrough to case's name"""
        return self.case.name
    
    @property
    def casename(self):
        """Passthrough to case's casename"""
        return self.case.casename
        
    def _filename(self, fntype, **kwargs):
        """Create a filename."""
        fn = Filename(self.config["IO.files"][fntype].get("directory",""),self.config["IO.files"][fntype]["template"])
        fn.format(self)
        return fn

    def __getattr__(self, attr, default):
        """A get attribute for returning filenames"""
        if attr in self.config["IO.files"]:
            return self._filename(attr)
        else:
            super(WCAOEstimate, self).__getattr__(attr, default)

