# -*- coding: utf-8 -*-
# 
#  core.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-04-29.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)


from ..core import BaseEstimator

import os, os.path

import numpy as np

from pyshell.util import force_dir_path

class BasePIDLYEstimator(BaseEstimator):
    """A base for PIDLY estimators"""
    
    method = ""
    path = []
    
    def __init__(self):
        """docstring for __init__"""
        from pkg_resources import resource_filename
        self.IDL = None
        self.path += [(resource_filename(__name__,force_dir_path("idl")),False)]
        
        
    def setup_path(self):
        """docstring for setup_path"""
        for path,expand in self.path:
            self._add_path(path,expand)
        
    def _add_path(self,path,expand=False):
        """Add an IDL path."""
        expand = "+" if expand else ""
        path = os.path.relpath(os.path.expanduser(path))
        self.IDL('!PATH=!PATH+":"+expand_path("{expand:s}{path:s}")'.format(
            expand = expand, path=path
        ))
        
    def _load(self,*items):
        """Make IDL load items."""
        for item in items:
            self.IDL(".r {:s}".format(item))