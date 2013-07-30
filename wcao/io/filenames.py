# -*- coding: utf-8 -*-
# 
#  filenames.py
#  aopy
#  
#  Created by Jaberwocky on 2013-07-29.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
"""
:mod:`filenames` – Support for format-string filenames
======================================================

"""

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import os, os.path
from string import Formatter

class DefaultKeyFormatter(Formatter):
    """Default key value formatter"""
    def get_value(self, key, args, kwargs):
            # Try standard formatting, then return 'unknown key'
            try:
                return super(DefaultKeyFormatter, self).get_value(key, args, kwargs)
            except KeyError:
                return kwargs.get(key, '{{{0}}}'.format(key))
        

class Filename(object):
    """A filename with string formatting tools."""
    def __init__(self, *args):
        super(Filename, self).__init__()
        self._template = os.path.join(*args)
        self._filepath = self._template
        self._formatted = False
        
    def __repr__(self):
        """Internal representation form."""
        if self.formatted:
            return "<{} '{!s}'>".format(self.__class__.__name__, self)
        else:
            return "<{} template='{!s}'>".format(self.__class__.__name__, self.template)
        
    def __str__(self):
        """Stringify this filename."""
        return self.filepath
        
    
    def _repr_pretty_(self, p, cycle):
        """Pretty representation."""
        p.text("Filename: '{!s}'".format(self))
    
    @property
    def formatted(self):
        """Boolean for formatted."""
        return self._formatted
        
    @property
    def filepath(self):
        """The full formatted filepath"""
        if not self.formatted:
            raise ValueError("{}: Not formatted yet!".format(self))
        return self._filepath
        
    def format(self,*args,**kwargs):
        """Format this filepath."""
        formatter = DefaultKeyFormatter()
        self._filepath = formatter.format(self._filepath,*args,**kwargs)
        self._formatted = True
        return self
        
    def __getattr__(self,attr):
        """Pass getattr through to os.path functions."""
        try:
            if not attr.startswith("_") and hasattr(os.path,attr):
                return getattr(os.path,attr)(self.filepath)
            else:
                raise TypeError
        except TypeError:
            raise AttributeError("{} does not have attribute '{}'".format(
                self, attr
            ))
        
            