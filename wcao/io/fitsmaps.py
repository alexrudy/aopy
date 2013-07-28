# -*- coding: utf-8 -*-
# 
#  fitsmaps.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-07-28.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)


import os, os.path
import warnings

import numpy as np

from .core import Reader, Writer

class MapReader(Reader):
    """Read map files from FITS"""
    
    def read(self, path="."):
        """Reads map objects from FITS files"""
        from astropy.io import fits
        filename = os.path.join(path,self.identifier + ".fits")
        
        with fits.open(filename) as HDUs:
            self.target.map = HDUs[0].data.copy()
            self.getheaders(HDUs[0])
        
    def getheaders(self, hdu):
        """Extract the map headers."""
        self.target.vx = np.linspace(float(hdu.header["WCAOmixv"]),float(hdu.header["WCAOmaxv"]),int(hdu.header["WCAOnuxv"]))
        self.target.vy = np.linspace(float(hdu.header["WCAOmiyv"]),float(hdu.header["WCAOmayv"]),int(hdu.header["WCAOnuyv"]))
        return super(MapReader, self).getheaders(hdu, wcaotype="WCAOWLLM")
        
    

class MapWriter(Writer):
    """Write map files to FITS"""
        
    def write(self, path="."):
        """docstring for fname"""
        from astropy.io import fits
        filename = os.path.join(path,self.identifier + ".fits")
        
        hdu = fits.PrimaryHDU(wmap)
        self.addheaders(hdu)
        hdu.writeto(filename, clobber=True)
        
    
    def addheaders(self,hdu):
        """docstring for addheaders"""
        hdu = super(MapReader, self).addheaders(hdu, wcaotype="WCAOWLLM")
        hdu.header["WCAOmaxv"] = (np.max(self.source.vx), "Maximum searched x velocity")
        hdu.header["WCAOmixv"] = (np.min(self.source.vx), "Minimum searched x velocity")
        hdu.header["WCAOnuxv"] = (len(self.source.vx), "Number of x velocity gridpoints")
        hdu.header["WCAOmayv"] = (np.max(self.source.vy), "Maximum searched y velocity")
        hdu.header["WCAOmiyv"] = (np.min(self.source.vy), "Minimum searched y velocity")
        hdu.header["WCAOnuyv"] = (len(self.source.vy), "Number of y velocity gridpoints")
        hdu.header["WCAOrecv"] = ("np.linspace(WCAOMI?V,WCAOMA?V,WCAONU?V)","Reconstruct velocity grids.")
        return hdu
    
        