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

from wcao.analysis.visualize import make_circles


class WCAOVerifyError(Exception):
    """An error class indicating that the header failed validation by the WCAO Module."""
    pass

class WCAOVerifyWarning(UserWarning):
    """A warning class indicating that the header failed validation by the WCAO Module"""
    
    def __repr__(self):
        return "{:s}".format(self.__class__.__name__)

def set_result_header_values(hdu, case=None, config=None):
    """Set the appropriate header values for a WCAO results file.
    
    :param hdu: The :mod:`astropy.io.fits` HDU
    :param case: The WCAOCase object. May be ``None``
    :param config: The Configuration Object. May be ``None``
    :return: The :mod:`astropy.io.fits` HDU
    
    Sets the following keywords:
    * `WCAOINST` - WCAO Instrument Name
    * `WCAOCASE` - WCAO Case Name
    * `WCAOHASH` - WCAO Configuration File Hash
    * `WCAOCONF` - WCAO Configuration File Name
    * `WCAOVERS` - WCAO File Version (1.0)
    * `WCAOTYPE` - WCAO File Type (data descriptor)
    
    """
    if case is not None:
        hdu.header['WCAOinst'] = (case.instrument, 'WCAO Instrument name')
        hdu.header['WCAOcase'] = (case.casename, 'WCAO Case Name')
    if config is not None:
        hdu.header['WCAOhash'] = (config.hash, 'Configuration File Hash')
        hdu.header['WCAOconf'] = (config.filename, 'Configuration File Name')
    return set_wcao_header_values(hdu)
    
def read_result_header_values(hdu, case, config):
    """Extract appropriate header values from the FMTS header, and check consistency.
    
    :param hdu: The :mod:`astropy.io.fits` HDU
    :param case: The WCAOCase object. May be ``None``
    :param config: The Configuration Object. May be ``None``
    :return: The :mod:`astropy.io.fits` HDU
    
    Verifies the following keywords:
    * `WCAOINST` - WCAO Instrument Name `Warning`
    * `WCAOCASE` - WCAO Case Name `Warning`
    * `WCAOHASH` - WCAO Configuration File Hash `Warning`
    * `WCAOCONF` - WCAO Configuration File Name `Ignored`
    * `WCAOVERS` - WCAO File Version (1.0) :exc:`ValueError`
    * `WCAOTYPE` - WCAO File Type (data descriptor) :exc:`Key Error` if it is missing.
    
    """
    verify_wcao_header_values(hdu, wcaotype=None)
    if config is not None:
        confighash = hdu.header["WCAOHASH"]
        if confighash != config.hash:
            warnings.warn("Configuration Hash Mismatch: got '{:s}', expected '{:s}'".format(confighash,config.hash),WCAOVerifyWarning)
    if case is not None:
        instrument = hdu.header['WCAOINST']
        if instrument != case.instrument:
            warnings.warn("Instrument Name Mismatch: got '{:s}', expected '{:s}'".format(instrument,case.instrument),WCAOVerifyWarning)
        casename = hdu.header["WCAOCASE"]
        if casename != case.casename:
            warnings.warn("Casename Mismatch: got '{:s}', expected '{:s}'".format(casename,case.casename),WCAOVerifyWarning)
    return hdu
            

def set_wcao_header_values(hdu, wcaotype='none'):
    """Set the WCAO header keywords.
    
    :param hdu: The :mod:`astropy.io.fits` HDU
    :param string wcaotype: The File Type value for this object.
    
    Sets:
    * `WCAOVERS` - WCAO File Version (1.0)
    * `WCAOTYPE` - WCAO File Type
    
    """
    hdu.header['WCAOvers'] = (1.0, 'WCAO file version')
    if not (wcaotype == 'none' and "WCAOTYPE" in hdu.header):
        hdu.header['WCAOtype'] = (wcaotype, 'data type for this HDU')
    else:
        wcaotype = None
    verify_wcao_header_values(hdu,wcaotype)
    return hdu
    

def verify_wcao_header_values(hdu, wcaotype='none'):
    """Verify WCAO header values."""
    if not hdu.header['WCAOvers'] >= 1.0:
        raise WCAOVerifyError("WCAO version number invalid: {:s}".format(hdu.header['WCAOvers']))
    if 'WCAOtype' not in hdu.header:
        raise WCAOVerifyError("WCAO header missing 'WCAOtype' keyword.")
    if wcaotype is not None and hdu.header['WCAOtype'] != wcaotype:
        raise WCAOVerifyError("WCAO type mismatch: got '{:s}', expected '{:s}'".format(hdu.header['WCAOtype'], wcaotype))
    return hdu

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
            self.config.get("{:s}.Data.directory".format(self.__class__.__name__),""),
            self.config.get("{:s}.Data.template".format(self.__class__.__name__),"{datatype:s}_{arraytype:s}_{instrument:s}_{name:s}.{ext:s}")
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
        fig.text(0.02,0.98,ltext,ha='left')
        
        today = datetime.date.today().isoformat()
        rtext = r"Analysis on {date:s} with {config:s}".format(date=today,config=self.case.config.hash)
        fig.text(0.98,0.98,rtext,ha='right')
        