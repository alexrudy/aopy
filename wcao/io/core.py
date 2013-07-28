# -*- coding: utf-8 -*-
# 
#  core.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-07-27.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)


import abc

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
    


def verify_wcao_header_values(hdu, wcaotype='none'):
    """Verify WCAO header values."""
    if not hdu.header['WCAOvers'] >= 1.0:
        raise WCAOVerifyError("WCAO version number invalid: {:s}".format(hdu.header['WCAOvers']))
    if 'WCAOtype' not in hdu.header:
        raise WCAOVerifyError("WCAO header missing 'WCAOtype' keyword.")
    if wcaotype is not None and hdu.header['WCAOtype'] != wcaotype:
        raise WCAOVerifyError("WCAO type mismatch: got '{:s}', expected '{:s}'".format(hdu.header['WCAOtype'], wcaotype))
    return hdu

class Reader(object):
    """A base class for io.readers"""
    def __init__(self, identifier, target):
        super(Reader, self).__init__()
        self.identifier = identifier
        self.target = target
        
    __metaclass__ = abc.ABCMeta
    
    @abc.abstractmethod
    def read(self, path="."):
        """Read the data from files."""
        pass
        
    def getheaders(self, hdu, wcaotype):
        """Extract appropriate header values from the FMTS header, and check consistency.
    
        :param hdu: The :mod:`astropy.io.fits` HDU
        :param wcaotype: the type stirng identifier
        :return: The :mod:`astropy.io.fits` HDU
    
        Verifies the following keywords:
        * `WCAOINST` - WCAO Instrument Name `Warning`
        * `WCAOCASE` - WCAO Case Name `Warning`
        * `WCAOHASH` - WCAO Configuration File Hash `Warning`
        * `WCAOCONF` - WCAO Configuration File Name `Ignored`
        * `WCAOVERS` - WCAO File Version (1.0) :exc:`ValueError`
        * `WCAOTYPE` - WCAO File Type (data descriptor) :exc:`Key Error` if it is missing.
    
        """
        if self.target.config is not None:
            confighash = hdu.header["WCAOHASH"]
            if confighash != self.target.config.hash:
                warnings.warn("Configuration Hash Mismatch: got '{:s}', expected '{:s}'".format(confighash,self.target.config.hash),
                    WCAOVerifyWarning)
        if self.target.case is not None:
            instrument = hdu.header['WCAOINST']
            if instrument != self.target.case.instrument:
                warnings.warn("Instrument Name Mismatch: got '{:s}', expected '{:s}'".format(instrument,self.target.case.instrument),
                    WCAOVerifyWarning)
            casename = hdu.header["WCAOCASE"]
            if casename != self.target.case.casename:
                warnings.warn("Casename Mismatch: got '{:s}', expected '{:s}'".format(casename,self.target.case.casename),
                    WCAOVerifyWarning)
        return hdu
        
class Writer(object):
    """A base class for io.writers"""
    def __init__(self, identifier, source):
        super(Writer, self).__init__()
        self.identifier = identifier
        self.source = source
        
    __metaclass__ = abc.ABCMeta
        
    @abc.abstractmethod
    def write(self, path="."):
        """Write the data to files."""
        pass
        
    def addheaders(self, hdu, wcaotype=None):
        """Set the appropriate header values for a WCAO results file.
    
        :param hdu: The :mod:`astropy.io.fits` HDU
        :param wcaotype: The WCAO File Type
        :return: The :mod:`astropy.io.fits` HDU
    
        Sets the following keywords:
        * `WCAOINST` - WCAO Instrument Name
        * `WCAOCASE` - WCAO Case Name
        * `WCAOHASH` - WCAO Configuration File Hash
        * `WCAOCONF` - WCAO Configuration File Name
        * `WCAOVERS` - WCAO File Version (1.0)
        * `WCAOTYPE` - WCAO File Type (data descriptor)
        
        """
        hdu.header['WCAOVERS'] = (1.0, 'WCAO file version')
        if not (wcaotype == 'none' and "WCAOTYPE" in hdu.header):
            hdu.header['WCAOTYPE'] = (wcaotype, 'data type for this HDU')
        else:
            wcaotype = None
        if self.source.case is not None:
            hdu.header['WCAOinst'] = (self.source.case.instrument, 'WCAO Instrument name')
            hdu.header['WCAOcase'] = (self.source.case.casename, 'WCAO Case Name')
        if self.source.config is not None:
            hdu.header['WCAOhash'] = (self.source.config.hash, 'Configuration File Hash')
            hdu.header['WCAOconf'] = (self.source.config.filename, 'Configuration File Name')
        verify_wcao_header_values(hdu,wcaotype)
        return hdu
        
        
        