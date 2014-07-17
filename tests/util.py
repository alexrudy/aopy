# -*- coding: utf-8 -*-
# 
#  util.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-08-12.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

"""
Testing Utilities
"""

import nose.tools as nt
from nose.plugins.attrib import attr

import os, os.path
import numpy as np
import warnings

def remove(path, warn=False, name='path'):
    """A silent remove."""
    try:
        os.remove(path)
    except OSError:
        if warn:
            warnings.warn("{name} '{path}' does not exist!".format(
                name=name.capitalize(), path=path
            )

def npeq_(a,b,msg, rtol=1e-8, atol=1e-4):
    """Assert numpy equal"""
    nt.ok_(np.allclose(a,b,rtol=rtol, atol=atol),"{:s} {!s}!={!s}".format(msg,a,b))

def npeq_or_save(a, b, rtol=1e-8, atol=1e-4, a_name=False, b_name=False, save=False):
    """Assert that things are equal. If they aren't, save the data to the postmortem directory."""
    
    if a_name:
        a_path = os.path.join(os.path.dirname(__file__),'postmortem/data/',a_name)
    if b_name:
        b_path = os.path.join(os.path.dirname(__file__),'postmortem/data/',b_name)
    
    result = np.allclose(a, b, rtol=rtol, atol=atol)
    
    if result and (not save):
        if a_name:
            remove(a_path)
        if b_name:
            remove(b_path)
    elif (not result) or save:
        if a_name:
            np.save(a_path, a)
        if b_name:
            np.save(b_path, b)
    
    return result

@attr(IDL=1)
class PIDLYTests(object):
    """Base class for tests that will use PIDLY"""
    
    IDL_PATHS = []
    IDL_OUTPUT = False
    IDL_LIBRARY = "IDL/library/"
    POSTMORTEM = []
    IDL_ENABLE = True
    
    def setup(self):
        """Open IDL session and add path."""
        if not self.IDL_ENABLE:
            return
        
        import pidly
        
        self.IDL = pidly.IDL()
        self.IDL("!PATH=expand_path(\"<IDL_default>\")", print_output=False)
        if self.IDL_LIBRARY:
            self.IDL_PATHS.append(self.IDL_LIBRARY)
        for PATH in self.IDL_PATHS:
            canonical = os.path.normpath(os.path.join(os.path.dirname(__file__),"..",PATH))
            self.IDL("!PATH=!PATH+\":\"+expand_path(\"{path}\")".format(path=canonical), print_output=False)
        
    def teardown(self):
        """Close IDL"""
        if not self.IDL_ENABLE:
            return
        self.IDL.close()
        
    @nt.nottest
    def postmortem(self):
        """Save any postmortem data if the test failed."""
        
    
        