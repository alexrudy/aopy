# -*- coding: utf-8 -*-
# 
#  core.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-29.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
"""
:class:`Aperture` – Making Apertures
------------------------------------
This module is useful for representing apertures. It uses algorithms from :ref:`util.math.aperture` in :mod:`util.math <aopy.util.math>`.

"""
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

from ..util.basic import is_type

import numpy as np

import warnings

__all__ = ['Aperture']

class Aperture(object):
    """A basic aperture object, for handling response, mask, and edge-mask functions.
    
    :param tuple response_shape: The shape of the full mask, if the full mask is responsive. ``np.ones((m,n))``
    :param numpy.ndarray response: The response function across the aperture. (Its ok to use a boolean array, if the response is not well defined.)
    
    """
    def __init__(self, response):
        self._response = None
        self._edgemask = False
        super(Aperture, self).__init__()
        self.response = response
        if self.response.ndim != 2:
            raise ValueError, "{0!r} response dimesnions should be 2, not {0.response.ndim:d}".format(
                self
            )
    
    def __shape_str__(self):
        """Turn the shape of the aperture into a string."""
        return "({:s})".format("x".join(map(str,self.shape)))
        
    def __str__(self):
        """A pretty string printing of this aperture."""
        return "Aperture shape {shape:s} open {per:.0f}%".format(
            shape = self.__shape_str__(),
            per = np.sum(self.pupil) / np.sum(np.ones_like(self.pupil)) * 100,
        )
        
    @property
    def pupil(self):
        """A boolean mask of the pupil plane. **Read-Only**"""
        return np.array(self._response != 0.0).astype(np.int)
        
    @property
    def response(self):
        """The original response function."""
        return np.copy(self._response)
        
    @response.setter
    def response(self,response):
        """Respons function setter."""
        if isinstance(response,tuple):
            response = np.ones(response,dtype=np.float)
        if not isinstance(self._edgemask,np.ndarray):
            pass 
        else:
            self._edgemask = False
        self._response = response
        self._response.flags.writeable = False
        
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
    
    @property
    def shape(self):
        """Shape of this aperture. **Read-Only**"""
        return self._response.shape
        
    def display_image(self,ax,**kwargs):
        """Show this aperture on the given axes.
        
        :param ax: A matplotlib axes instance on which to show the image.
        :keyword kwargs: Any extra keywords which will be passed to :meth:`~matplotlib.axes.Axes.imshow`."""
        kwargs.setdefault('interpolation','nearest')
        return ax.imshow(self.pupil,**kwargs)
        
class DMAperture(Aperture):
    """This is an aperture designed to hold DM actuator positions.
    
    :param int n: Deformable mirror dimensions
    :param int l: The bottom of the DM window
    :param int h: The top of the DM window
    
    """
    def __init__(self, n, l=None, h=None):
        
        if isinstance(n,np.ndarray):
            response = n
            loc = np.where(np.sum(response,axis=0) != 0)[0]
            lx = loc[0]
            hx = loc[-1]
            loc = np.where(np.sum(response,axis=1) != 0)[0]
            ly = loc[0]
            hy = loc[-1]
            if lx == ly and hx == hy:
                l = lx
                h = hx
            else:
                ValueError("{!r} does not have a square aperture visible: X({},{}) Y({},{})".format(self,lx,hx,ly,hy))
        elif is_type(n,int):
            l = l or 0
            h = h or n
            response = np.zeros((n,n),dtype=np.float)
            response[l:h,l:h] = 1.0
        else:
            raise ValueError("n={0!r} is not a valid response specifier. Must be an <int> or <ndarray>.".format(n))
        
        super(DMAperture, self).__init__(response)
        self._dmlh = (l,h)
        
    _dmlh = None
        
    @property
    def dmlh(self):
        """The window parameters for this DM. **Read Only**"""
        return self._dmlh
        
        