# -*- coding: utf-8 -*-
# 
#  core.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-29.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np

import warnings

__all__ = ['Aperture']

class Aperture(object):
    """A basic aperture"""
    def __init__(self, response):
        super(Aperture, self).__init__()
        if isinstance(response,tuple):
            self._response = np.ones(response)
        else:
            self._response = np.array(response)
        if self._response.ndim != 2:
            raise ValueError, "{0!r} response dimesnions should be 2, not {:d}".format(
                self, self._response.ndim
            )
        self._edgemask = False
        self._edgemask_generated = True
        
    @property
    def pupil(self):
        """Return the full pupil plane"""
        return np.array(self._response != 0.0).astype(np.int)
        
    @property
    def response(self):
        """Get the response array"""
        return self._response
        
    @response.setter
    def response(self,response):
        """docstring for response"""
        if not isinstance(self._edgemask,np.ndarray):
            pass 
        elif self._edgemask_generated:
            self._edgemask = False
        elif self._edgemask.shape != response.shape:
            raise ValueError("Response {0!s} and Edgemask {0!s} must have the same shape.")
        self._response = response
        
    @property
    def edgemask(self):
        """return the pupil without edges"""
        if isinstance(self._edgemask,np.ndarray):
            return self._edgemask
        else:
            from ..util.math import edgemask
            self._edgemask = edgemask(self._response).astype(np.int)
            self._edgemask_generated = True
            return self._edgemask
            
    @edgemask.setter
    def edgemask(self,mask):
        """Set the edgemask"""
        if not isinstance(mask,np.ndarray) and mask is False:
            self._edgemask = False
        else:
            mask = np.array(mask)
            if mask.shape != self.response.shape:
                raise ValueError("New edgemask {0!s} must have the same shape as the response matrix {0!s}".format(
                    mask.shape, self.response.shape
                ))
            self._edgemask = mask
            self._edgemask_generated = False
    
    @property
    def shape(self):
        """Return the shape of this aperture"""
        return self._response.shape
        
    def display_image(self,ax):
        """Show this aperture on the given axes"""
        ax.imshow(self.pupil,interpolation='nearest')