# -*- coding: utf-8 -*-
# 
#  core.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-29.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
"""
:mod:`aperture.core <aopy.aperture.core>` – Aperture Classes
============================================================

This module is useful for representing apertures. It uses algorithms from :ref:`util.math.aperture` in :mod:`util.math <aopy.util.math>`.

:class:`Aperture` – Making Apertures
------------------------------------

.. autoclass::
    Aperture
    :members:

"""
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np

import warnings

__all__ = ['Aperture']

class Aperture(object):
    """A basic aperture object, for handling response, mask, and edge-mask functions.
    
    :param tuple response_shape: The shape of the full mask, if the full mask is responsive. ``np.ones((m,n))``
    :param numpy.ndarray response: The response function across the aperture. (Its ok to use a boolean array, if the response is not well defined.)
    
    """
    def __init__(self, response):
        super(Aperture, self).__init__()
        self._edgemask = False
        self._edgemask_generated = True
        self.response = response
        if self.response.ndim != 2:
            raise ValueError, "{0!r} response dimesnions should be 2, not {:d}".format(
                self, self.response.ndim
            )
        
    @property
    def pupil(self):
        """A boolean mask of the pupil plane. **Read-Only**"""
        return np.array(self._response != 0.0).astype(np.int)
        
    @property
    def response(self):
        """The original response function."""
        return self._response
        
    @response.setter
    def response(self,response):
        """Respons function setter."""
        if isinstance(response,tuple):
            response = np.ones(response)
        if not isinstance(self._edgemask,np.ndarray):
            pass 
        elif self._edgemask_generated:
            self._edgemask = False
        elif self._edgemask.shape != response.shape:
            raise ValueError("Response {0!s} and Edgemask {0!s} must have the same shape.")
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
        """Shape of this aperture. **Read-Only**"""
        return self._response.shape
        
    def display_image(self,ax,**kwargs):
        """Show this aperture on the given axes.
        
        :param ax: A matplotlib axes instance on which to show the image.
        :keyword kwargs: Any extra keywords which will be passed to :meth:`~matplotlib.axes.Axes.imshow`."""
        kwargs.setdefault('interpolation','nearest')
        return ax.imshow(self.pupil,**kwargs)
        