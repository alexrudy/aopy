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

from aopy.util.basic import resolve
from .case import WCAOData

class WCAOEstimate(WCAOData):
    """A reperesentation of any WCAO data"""
    
    __metaclass__ = abc.ABCMeta
    
    def __init__(self, case, datatype="", **kwargs):
        super(WCAOEstimate, self).__init__(case=case)
        self.datatype = datatype
        self.init_data(**kwargs)
        
    def __repr__(self):
        """String representation of a result."""
        return "<{0.__class__.__name__}:{0.datatype:s} array={0.arraytype:s}, name={0.description:s}>".format(self)
        
    def _repr_pretty_(self, p, cycle):
        """Pretty print result"""
        p.text("{0.datatype:s} array={0.arraytype:s}, name={0.description:s}".format(self))
        
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
        return self.config["Data.Estimators.Types"][self.datatype]["description"]
        
    @property
    def arraytype(self):
        """Expose the array type code"""
        return self.config["Data.Estimators.Types"][self.datatype]["array"]
        
    @abc.abstractproperty
    def data(self):
        """Get the actual data!"""
        raise NotImplementedError("{!r} has no concept of data!".format(self))
        
    @abc.abstractmethod
    def init_data(self,**kwargs):
        """This method has no idea how to initialize data!"""
        raise NotImplementedError("{!r} has no concept of data!".format(self))
        
    
    def save(self):
        """Save this result to a file."""
        fn = self._filename('data')
        io_class = resolve(self.config["Data.Estimators.Types"][self.datatype]["ioclass"])
        io_obj = io_class(fn, self)
        io_obj.write()
        
    def load(self):
        """Load this result from a file."""
        fn = self._filename('data')
        io_class = resolve(self.config["Data.Estimators.Types"][self.datatype]["ioclass"])
        io_obj = io_class(fn, self)
        io_obj.read()
        
        
        