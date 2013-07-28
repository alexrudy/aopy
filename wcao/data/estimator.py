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
import warnings
import datetime

import numpy as np

from astropy.io import fits

import pyshell
from pyshell.config import DottedConfiguration

from .. import WCAOData

class WCAOEstimate(WCAOData):
    """A reperesentation of any WCAO data"""
    
    LONGNAMES = {
        'GN' : "Gauss Newton",
        'RT' : "Radon Transform",
        '2D' : "2D Binary Search",
        'XY' : "Split 2D Binary Search",
        'FT' : "Time-Domain Fourier Transform",
        '2L' : "2-Layer Gauss Newton",
        'FS' : "Time-Domain Fourier Transform Series"
    }
    
    ARRAYTYPE = {
    'GN' : "NLTS",
    'RT' : "NLTS",
    '2D' : "NLTS",
    'XY' : "NLTS",
    'FT' : "WLLM",
    '2L' : "NLTS",
    'FS' : "NLTS",
    }
    
    __metaclass__ = abc.ABCMeta
    
    def __init__(self, case, data=None, datatype=""):
        super(WCAOEstimate, self).__init__(case=case)
        if datatype not in self.ARRAYTYPE or datatype not in self.LONGNAMES:
            raise ValueError("Unknown data type {:s}. Options: {!r}".format(name,self.DATATYPE.keys()))
        self._datatype = datatype
        self._arraytype = self.ARRAYTYPE[self._datatype]
        self._data = data
        self._config = self.case.config
        self._figurename = os.path.join(
            self.config.get("Data.figure.directory",""),
            self.config["Data.figure.template"],
            )
        self._dataname = os.path.join(
            self.config.get("Data.output.directory",""),
            self.config["Data.output.template"]
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
        
    def dataname(self,ext):
        """The fits-file name for this object"""
        return self._dataname.format(
            instrument = self.case.instrument,
            name = self.case.casename,
            ext = ext,
            datatype = self._datatype,
            arraytype = self._arraytype,
        )
        
    @property
    def fitsname(self):
        """The fits-file name for this object"""
        return self._dataname.format(
            instrument = self.case.instrument,
            name = self.case.casename,
            ext = self.config.get("WCAOEstimate.Data.fits.ext","fits"),
            datatype = self._datatype,
            arraytype = self._arraytype,
        )
        
    @property
    def npyname(self):
        """Numpy file name for this object"""
        return self._dataname.format(
            instrument = self.case.instrument,
            name = self.case.casename,
            ext = self.config.get("WCAOEstimate.Data.npy.ext","npy"),
            datatype = self._datatype,
            arraytype = self._arraytype,
        )
    
    def figname(self, ext, figtype):
        """Figure name"""
        return self._figurename.format(
            instrument = self.case.instrument,
            name = self.case.casename,
            ext = ext,
            datatype = self._datatype,
            figtype = figtype,
        )
        
    @abc.abstractmethod
    def _init_data(self,data):
        """This method has no idea how to initialize data!"""
        raise NotImplementedError("{!r} has no concept of data!".format(self))
        
    
    @abc.abstractmethod
    def save(self):
        """Save this result to a file."""
        pass
        
    @abc.abstractmethod
    def load(self):
        """Load this result from a file."""
        pass
        
    
    def _header(self,fig):
        """Add this object's header"""
        inst = self.case.instrument.replace("_"," ")
        ltext = r"{instrument:s} during \verb|{casename:s}|".format(instrument=inst,casename=self.case.casename)
        fig.text(0.02,0.98,ltext,ha='left',va='top')
        
        today = datetime.date.today().isoformat()
        rtext = r"Analysis on {date:s} with {config:s}".format(date=today,config=self.case.config.hash)
        fig.text(0.98,0.98,rtext,ha='right',va='top')
        