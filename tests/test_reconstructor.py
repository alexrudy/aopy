# -*- coding: utf-8 -*-
# 
#  test_reconstructor.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-08-14.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import nose.tools as nt
from nose.plugins.skip import SkipTest
import numpy as np

import os, os.path

from pyshell.util import remove
import pidly

from .util import npeq_, PIDLYTests, npeq_or_save

from aopy.reconstructors.ftr import FixedFilterFTR

class test_reconstructor(PIDLYTests):
    """Tests for reconstructor"""
    
    IDL_PATHS = ['IDL/reconstructors','IDL/libary']
    IDL_OUTPUT = True
    
    def setup(self):
        """Set up the PIDLY session etc."""
        super(test_reconstructor, self).setup()
        self.IDL(".compile apply_ftr_filter.pro")
        self.IDL(".compile ftr_filter.pro")
        self.size = 40
        
    def test_mod_hud_filter(self):
        """mod-hud filter"""
        self.IDL("ftr_filter, gx, gy, {0.size}".format(self))
        self.IDL("gx_r = real_part(gx)")
        self.IDL("gy_r = real_part(gy)")
        self.IDL("gx_i = imaginary(gx)")
        self.IDL("gy_i = imaginary(gy)")
        gx_idl = self.IDL.gx_r
        gy_idl = self.IDL.gy_r
        gx_idl = gx_idl + (1j * self.IDL.gx_i)
        gy_idl = gy_idl + (1j * self.IDL.gy_i)
        
        FTR = FixedFilterFTR(self.size, filtername='mod_hud')
        gx_pyt = FTR.gx
        gy_pyt = FTR.gy
        gy_result = npeq_or_save(gy_idl, gy_pyt, a_name="gy_idl_mod_hud.npy", b_name="gy_pyt_mod_hud.npy")        
        gx_result = npeq_or_save(gx_idl, gx_pyt, a_name="gx_idl_mod_hud.npy", b_name="gx_pyt_mod_hud.npy", save=not gy_result)
        gy_result = npeq_or_save(gy_idl, gy_pyt, a_name="gy_idl_mod_hud.npy", b_name="gy_pyt_mod_hud.npy", save=not gx_result)
        
        nt.ok_(gx_result, "GX-Mismatch")
        nt.ok_(gy_result, "GY-Mismatch")
        
    def test_ideal_filter(self):
        """ideal filter"""
        self.IDL("ftr_filter, gx, gy, {0.size}, /ideal".format(self))
        self.IDL("gx_r = real_part(gx)")
        self.IDL("gy_r = real_part(gy)")
        self.IDL("gx_i = imaginary(gx)")
        self.IDL("gy_i = imaginary(gy)")
        gx_idl = self.IDL.gx_r
        gy_idl = self.IDL.gy_r
        gx_idl = gx_idl + (1j * self.IDL.gx_i)
        gy_idl = gy_idl + (1j * self.IDL.gy_i)
        
        FTR = FixedFilterFTR(self.size, filtername='ideal')
        gx_pyt = FTR.gx
        gy_pyt = FTR.gy
        
        gy_result = npeq_or_save(gy_idl, gy_pyt, a_name="gy_idl_ideal.npy", b_name="gy_pyt_ideal.npy")   
        gx_result = npeq_or_save(gx_idl, gx_pyt, a_name="gx_idl_ideal.npy", b_name="gx_pyt_ideal.npy", save=not gy_result)
        gy_result = npeq_or_save(gy_idl, gy_pyt, a_name="gy_idl_ideal.npy", b_name="gy_pyt_ideal.npy", save=not (gy_result and gx_result))
        
        nt.ok_(gx_result, "GX-Mismatch")
        nt.ok_(gy_result, "GY-Mismatch")