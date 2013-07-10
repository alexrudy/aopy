# -*- coding: utf-8 -*-
# 
#  data.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-30.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 


from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import abc, collections
import os, os.path

import numpy as np

from astropy.io import fits

import pyshell
from pyshell.config import DottedConfiguration

from wcao.analysis.visualize import make_circles

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
    
    def __init__(self, case, data=None, datatype=""):
        super(WCAOEstimate, self).__init__()
        self.log = pyshell.getLogger(__name__)
        if datatype not in self.ARRAYTYPE or datatype not in self.LONGNAMES:
            raise ValueError("Unknown data type {:s}. Options: {!r}".format(name,self.DATATYPE.keys()))
        self.case = case
        self._datatype = datatype
        self._arraytype = self.ARRAYTYPE[self._datatype]
        self._data = data
        self._config = self.case.config
        self._figurename = os.path.join(
            self.config.get("data.figure.directory","figures"),
            self.config.get("data.figure.template","{datatype:s}_{figtype:s}_{instrument:s}_{name:s}.{ext:s}"),
            )
        self._dataname = os.path.join(
            self.config.get("WCAOEstimate.Data.directory",""),
            self.config.get("WCAOEstimate.Data.template","{datatype:s}_{arraytype:s}_{instrument:s}_{name:s}.{ext:s}")
        )
        self._init_data(data)
        
    def __str__(self):
        """Pretty string ASCII-table representation of a result."""
        return "{0._datatype:s}: array={0._arraytype:s}, name={0.longname:s}".format(self)
        
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
            instrument = self.case.instrument,
            name = self.case.casename,
            ext = self.config.get("WCAOEstimate.Data.fits.ext","fits"),
            datatype = self._datatype,
            arraytype = self._arraytype,
        )
        
    @property
    def npyname(self):
        """Numpy file name for this object"""
        return self._fitsname.format(
            instrument = self.case.instrument,
            name = self.case.casename,
            ext = self.config.get("WCAOEstimate.Data.npy.ext","npy"),
            datatype = self._datatype,
            arraytype = self._arraytype,
        )
    
    @property
    def figname(self):
        """Figure name"""
        return self._figurename.format(
            instrument = self.case.instrument,
            name = self.case.casename,
            ext = self.config.get("WCAOEstimate.Data.npy.ext","npy"),
            datatype = self._datatype,
            figtype = "{figtype:s}",
        )
        
    @abc.abstractmethod
    def _init_data(self,data):
        """This method has no idea how to initialize data!"""
        raise NotImplementedError("{!r} has no concept of data!".format(self))
        


        
        
        