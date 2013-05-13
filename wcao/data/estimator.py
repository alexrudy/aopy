# -*- coding: utf-8 -*-
# 
#  estimator.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-05.
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

class WCAOEstimate(object):
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
        super(WCAOEstimate, self).__init__()
        if datatype not in self.ARRAYTYPE or datatype not in self.LONGNAMES:
            raise ValueError("Unknown data type {:s}. Options: {!r}".format(name,self.DATATYPE.keys()))
        self.name = obsname
        self.instrument = instname
        self._datatype = datatype
        self._arraytype = self.ARRAYTYPE[self._datatype]
        self._winddata = winddata
        self._config = DottedConfiguration.make(config)
        self._figurename = os.path.join(
            self.config.get("WCAOEstimate.Figure.directory","figures"),
            self.config.get("WCAOEstimate.Figure.template","{datatype:s}_{figtype:s}_{instrument:s}_{name:s}.{ext:s}"),
            )
        self._dataname = os.path.join(
            self.config.get("WCAOEstimate.Data.directory",""),
            self.config.get("WCAOEstimate.Data.template","{datatype:s}_{arraytype:s}_{instrument:s}_{name:s}.{ext:s}")
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
            ext = self.config.get("WCAOEstimate.Data.fits.ext","fits"),
            datatype = self._datatype,
            arraytype = self._arraytype,
        )
        
    @property
    def npyname(self):
        """Numpy file name for this object"""
        return self._fitsname.format(
            instrument = self.instrument,
            name = self.name,
            ext = self.config.get("WCAOEstimate.Data.npy.ext","npy"),
            datatype = self._datatype,
            arraytype = self._arraytype,
        )
    
    @property
    def figname(self):
        """Figure name"""
        return self._figurename.format(
            instrument = self.instrument,
            name = self.name,
            ext = self.config.get("WCAOEstimate.Figure.savefig.ext","pdf"),
            datatype = self._datatype,
            figtype = "{figtype:s}",
        )
        
    @abc.abstractmethod
    def _init_data(self,data):
        """This method has no idea how to initialize data!"""
        raise NotImplementedError("{!r} has no concept of data!".format(self))