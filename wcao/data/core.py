# -*- coding: utf-8 -*-
# 
#  core.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-01.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import abc
import os, os.path

import numpy as np

from astropy.io import fits

import pyshell
from pyshell.config import DottedConfiguration

class WCAOCase(object):
    """A representation of a specific WCAO data case."""
    def __init__(self, instrument, casename, configuration):
        super(WCAOCase, self).__init__()
        self.config = DottedConfiguration.make(configuration)
        self.instrument = instrument
        self.casename = casename
        
    @property
    def name(self):
        """Return the full name"""
        return "{0.instrument:s}-{0.casename:s}".format(self)
        
        
    def load_raw(self):
        """Load raw data."""
        pass
        
    def load_phase(self):
        """docstring for phase"""
        pass
    

class WCAOData(object):
    """A reperesentation of any WCAO data"""
    
    LONGNAMES = {
        'GN' : "Gauss Newton",
        'RT' : "Radon Transform",
        '2D' : "2D Binary Search",
        'XY' : "Split 2D Binary Search",
        'FT' : "Time-Domain Fourier Transform",
        '2L' : "2-Layer Gauss Newton",
    }
    
    ARRAYTYPE = {
    'GN' : "NLTS",
    'RT' : "NLTS",
    '2D' : "NLTS",
    'XY' : "NLTS",
    'FT' : "WLLM",
    '2L' : "NLTS",
    }
    
    __metaclass__ = abc.ABCMeta
    
    def __init__(self, datatype="", obsname="", instname="", winddata=None, config={}):
        super(WCAOData, self).__init__()
        if datatype not in self.ARRAYTYPE or datatype not in self.LONGNAMES:
            raise ValueError("Unknown data type {:s}. Options: {!r}".format(name,self.DATATYPE.keys()))
        self.name = obsname
        self.instrument = instname
        self._datatype = datatype
        self._arraytype = self.ARRAYTYPE[self._datatype]
        self._winddata = winddata
        self._config = DottedConfiguration.make(config)
        self._figurename = os.path.join(
            self.config.get("WCAOData.Figure.directory","figures"),
            self.config.get("WCAOData.Figure.template","{datatype:s}_{figtype:s}_{instrument:s}_{name:s}.{ext:s}"),
            )
        self._dataname = os.path.join(
            self.config.get("WCAOData.Data.directory",""),
            self.config.get("WCAOData.Data.template","{datatype:s}_{arraytype:s}_{instrument:s}_{name:s}.{ext:s}")
        )
        self._init_data(data)
        self.log = pyshell.getLogger(__name__)
        
    @property
    def config(self):
        """The configuration!"""
        return self._config
        
    @property
    def longname(self):
        """Expose a long name"""
        return self.LONGNAMES[self._datatype]
        
    @property
    def data(self):
        """Get the actual data!"""
        return self._data
        
    @property
    def fitsname(self):
        """The fits-file name for this object"""
        return self._fitsname.format(
            instrument = self.instrument,
            name = self.name,
            ext = self.config.get("WCAOData.Data.fits.ext","fits"),
            datatype = self._datatype,
            arraytype = self._arraytype,
        )
        
    @property
    def npyname(self):
        """Numpy file name for this object"""
        return self._fitsname.format(
            instrument = self.instrument,
            name = self.name,
            ext = self.config.get("WCAOData.Data.npy.ext","npy"),
            datatype = self._datatype,
            arraytype = self._arraytype,
        )
    
    @property
    def figname(self):
        """Figure name"""
        return self._figurename.format(
            instrument = self.instrument,
            name = self.name,
            ext = self.config.get("WCAOData.Data.npy.ext","npy"),
            datatype = self._datatype,
            figtype = "{figtype:s}",
        )
        
    @abc.abstractmethod
    def _init_data(self,data):
        """This method has no idea how to initialize data!"""
        raise NotImplementedError("{!r} has no concept of data!".format(self))
        
