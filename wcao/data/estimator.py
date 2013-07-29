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
    
    __metaclass__ = abc.ABCMeta
    
    def __init__(self, case, data=None, datatype=""):
        super(WCAOEstimate, self).__init__(case=case)
        self.datatype = datatype
        self._init_data(data)
        
    def __str__(self):
        """Pretty string ASCII-table representation of a result."""
        return "{0._datatype:s}: array={0._arraytype:s}, name={0.longname:s}".format(self)
        
    @property
    def datatype(self):
        """The data type property"""
        return self._datatype
        
    @datatype.setter
    def datatype(self, datatype):
        """Set the data type value"""
        if datatype not in self.config["Data.Estimators.Types"]:
            raise KeyError("{}: Unknown data type {}, choices: {!r}".format(
                self, datatype, self.config["Data.Estimators.Types"].keys()
            ))
        
        self._datatype = datatype
        
    @property
    def description(self):
        """Expose a long name"""
        return self.config["Data.Estimators.Types"][datatype]["description"]
        
    @property
    def arraytype(self):
        """Expose the array type code"""
        return self.config["Data.Estimators.Types"][datatype]["array"]
        
    @property
    def data(self):
        """Get the actual data!"""
        return self._data
        
        
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
        