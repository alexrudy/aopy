# -*- coding: utf-8 -*-
# 
#  idl.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-07-27.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

"""
:mod:`wcao.io.idl` – Loading IDL data
=====================================

"""

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import os, os.path
import warnings

import numpy as np

from .core import Reader, Writer

class MapReader(Reader):
    """Read IDL 3-extension maps"""
    
    def read(self, path="."):
        """Load wind map information from IDL"""
        from astropy.io import fits
        
        filename = os.path.join(path,self.identifier + ".fits")
        
        data = {}
        
        with fits.open(filename) as HDUs:
            for HDU in HDUs:
                if HDU.header["DTYPE"] == 'Wind Map':
                    self.target.map = HDU.data.copy()
                elif HDU.header["DTYPE"] == 'Wind vx scale':
                    self.target.vx = HDU.data.copy()
                elif HDU.header["DTYPE"] == 'Wind vy scale':
                    self.target.vy = HDU.data.copy()
                elif HDU.header["DTYPE"] == 'Wind Layer List':
                    layer_list = np.atleast_2d(HDU.data.copy())
                    self.target.layers = getattr(self.target,'layers',[])
                    for row in layer_list:
                        self.target.layers.append({
                            "vx" : row[0],
                            "vy" : row[1],
                            "m"  : row[2],
                        })
        
        if self.target.map.shape != (self.target.vx.shape + self.target.vy.shape):
            warnings.warn("Map scale data does not match map shape: {} != {}".format(
                self.target.map.shape, (self.target.vx.shape + self.target.vy.shape)
            ))
            
    
class MapWriter(Writer):
    """Write IDL 3-extension maps."""
    
    
    def write(self, path="."):
        """Write wind map information to IDL"""
        from astropy.io import fits
        
        HDU_map = fits.PrimaryHDU(self.source.map)
        HDU_map.header["DTYPE"] = ('Wind Map', 'In spatial domain')
        
        HDU_vx = fits.ImageHDU(self.source.vx)
        HDU_vx.header["DTYPE"] = ('Wind vx scale', 'in m/s')
        
        HDU_vy = fits.ImageHDU(self.source.vy)
        HDU_vy.header["DTYPE"] = ('Wind vy scale', 'in m/s')
        
        HDUs = fits.HDUList([HDU_map, HDU_vx, HDU_vy])
        if getattr(self.source,'layers',False):
            shape = (len(self.source.layers),4)
            layers = np.zeros(shape)
            for i,layer in enumerate(self.source.layers):
                layers[i,0] = layer["vx"]
                layers[i,1] = layer["vy"]
                layers[i,2] = layer["m"]
            HDU_layers = fits.ImageHDU(layers)
            HDU_layers.header["DTYPE"] = ('Wind Layer List', '')
            HDUs.append(HDU_layers)
        map(self.addheader,HDUs)
        filename = os.path.join(path,self.identifier)
        HDUs.writeto(filename, clobber=True)
        
    def addheader(self,hdu):
        """Add IDL type-headers"""
        HDU.header["TSCOPE"] = self.source.case.instrument
        
    


