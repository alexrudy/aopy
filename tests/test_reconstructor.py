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

import pidly

from .util import npeq_, PIDLYTests, npeq_or_save

from aopy.reconstructors.ftr import FixedFilterFTR

class test_reconstructor(PIDLYTests):
    """aopy.reconstructors.ftr"""
    
    IDL_PATHS = ['IDL/reconstructors']
    IDL_OUTPUT = True
    
    def setup(self):
        """Set up the PIDLY session etc."""
        super(test_reconstructor, self).setup()
        self.IDL(".compile apply_ftr_filter.pro")
        self.IDL(".compile ftr_filter.pro")
        self.size = 40
        self.radius = 19.0
        n = self.size/2
        self.Xs, self.Ys = np.mgrid[-n:n,-n:n] / self.radius
        self.X, self.Y = np.mgrid[-n:n,-n:n]
        self.ap = (np.sqrt(self.X**2.0 + self.Y**2.0) < self.radius).astype(np.int)
        
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
        
    def test_focus_reconstructor(self):
        """focus reconstructor"""
        self.reconstructor(2, 0)
        
    def test_focus_reconstructor_ap(self):
        """focus reconstructor with aperture"""
        self.reconstructor_with_ap(2, 0)
        
    def test_focus_reconstructor_sm(self):
        """focus reconstructor with slope manage"""
        self.reconstructor_with_slopemanage(2, 0)
        
    def test_tt_reconstructor(self):
        """tip/tilt reconstructor"""
        self.reconstructor(1, 1)
        self.reconstructor(1, -1)
        
    def test_tt_reconstructor_ap(self):
        """tip/tilt reconstructor with aperture"""
        self.reconstructor_with_ap(1, 1)
        self.reconstructor_with_ap(1, -1)
        
    def test_tt_reconstructor_sm(self):
        """tip/tilt reconstructor with slope manage"""
        self.reconstructor_with_slopemanage(1, 1)
        self.reconstructor_with_slopemanage(1, -1)
        
    @nt.nottest
    def reconstructor(self, n, m):
        """Reconstructor!"""
        from aopy.wavefront.zernike import zernike_slope_cartesian
        xs, ys = zernike_slope_cartesian(n, m, self.Xs, self.Ys)
        
        self.IDL.xs = ys.T
        self.IDL.ys = xs.T
        self.IDL("zs = apply_ftr_filter(xs, ys)")
        zs_idl = self.IDL.zs.T
        
        FTR = FixedFilterFTR(self.size, filtername='mod_hud')
        zs_pyt = FTR.reconstruct(xs, ys)
        
        zs_result = npeq_or_save(zs_idl, zs_pyt, a_name="zs_idl_mod_hud_{n:d}_{m:d}.npy".format(n=n,m=m),
            b_name="zs_pyt_mod_hud_{n:d}_{m:d}.npy".format(n=n,m=m))
        nt.ok_(zs_result, "Zs Mismatch")
        
    @nt.nottest
    def reconstructor_with_ap(self, n, m):
        """Reconstructor!"""
        from aopy.wavefront.zernike import zernike_slope_cartesian
        xs, ys = zernike_slope_cartesian(n, m, self.Xs, self.Ys)
        
        xs = xs * self.ap
        ys = ys * self.ap
        
        self.IDL.xs = ys.T
        self.IDL.ys = xs.T
        self.IDL("zs = apply_ftr_filter(xs, ys)")
        zs_idl = self.IDL.zs.T
        
        FTR = FixedFilterFTR(self.size, filtername='mod_hud')
        zs_pyt = FTR.reconstruct(xs, ys)
        
        zs_result = npeq_or_save(zs_idl, zs_pyt, a_name="zs_idl_mod_hud_{n:d}_{m:d}_ap.npy".format(n=n,m=m),
            b_name="zs_pyt_mod_hud_{n:d}_{m:d}_ap.npy".format(n=n,m=m))
        nt.ok_(zs_result, "Zs Mismatch")
        
    @nt.nottest
    def reconstructor_with_slopemanage(self, n, m):
        """Reconstructor!"""
        from aopy.wavefront.zernike import zernike_slope_cartesian
        from aopy.aperture.slopemanage import slope_management
        xs, ys = zernike_slope_cartesian(n, m, self.Xs, self.Ys)
        
        xs = xs * self.ap
        ys = ys * self.ap
        
        self.IDL.xs = ys.T
        self.IDL.ys = xs.T
        self.IDL.ap = self.ap.T
        self.IDL("slope_management, ap, xs, ys")
        self.IDL("xs_sm = xs")
        self.IDL("ys_sm = ys")
        self.IDL("zs = apply_ftr_filter(xs_sm, ys_sm)")
        zs_idl = self.IDL.zs.T
        
        xs_m, ys_m = slope_management(self.ap, xs, ys)
        FTR = FixedFilterFTR(self.size, filtername='mod_hud')
        zs_pyt = FTR.reconstruct(xs_m, ys_m)
        
        zs_result = npeq_or_save(zs_idl, zs_pyt, a_name="zs_idl_mod_hud_{n:d}_{m:d}_sm.npy".format(n=n,m=m),
            b_name="zs_pyt_mod_hud_{n:d}_{m:d}_sm.npy".format(n=n,m=m))
        nt.ok_(zs_result, "Zs Mismatch")