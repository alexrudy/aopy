# -*- coding: utf-8 -*-
# 
#  test_zernike.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-08-12.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)
import nose.tools as nt
from nose.plugins.skip import SkipTest
import numpy as np

import os, os.path

import pidly

from .util import npeq_, PIDLYTests

from aopy.wavefront import zernike

class test_zernike_polynomials(PIDLYTests):
    """aopy.wavefront.zernike functions"""
    
    IDL_PATHS = ["IDL/zernike/"]
    
    def setup(self):
        """Initialize IDL"""
        super(test_zernike_polynomials, self).setup()
        self.size = 40
        self.radius = 19.0
        self.circle_args = {
            'size': self.size,
            'center': self.size/2,
            'radius': self.radius,
            'value' : 1,
        }
        self.IDL('.compile zernike.pro',print_output=self.IDL_OUTPUT)
        self.IDL('ap = circle({size},{size},{center},{center},{radius},{value})'.format(
            ** self.circle_args
        ), print_output=self.IDL_OUTPUT)
        self.X, self.Y = np.mgrid[-self.size/2:self.size/2,-self.size/2:self.size/2] / self.radius
        self.ap = (np.sqrt(self.X**2 + self.Y**2) < 1).astype(np.int)
    
    def teardown(self):
        """Teardown IDL"""
        super(test_zernike_polynomials, self).teardown()
        
    @nt.nottest
    def zernike_tests(self, n, m):
        """Zernike Mode Tests"""
        zernike_args = self.circle_args
        zernike_args["n"] = n
        zernike_args["m"] = m
        self.IDL('zs = zernike({size},{size},{radius},{n},{m},/noll)'.format(**zernike_args), print_output=self.IDL_OUTPUT)
        z_idl = self.IDL.zs.T
        z_idl = z_idl * self.ap
        
        z_pyt = zernike.zernike_cartesian(n, m, self.X, self.Y) * self.ap
        
        idl_filename = "z_idl_{n:d}_{m:d}.npy".format(n=n,m=m)
        pyt_filename = "z_pyt_{n:d}_{m:d}.npy".format(n=n,m=m)
        
        self.POST_SAVE = [
            (z_idl, idl_filename),
            (z_pyt, pyt_filename)
        ]
        
        gap = z_idl[self.ap == 1]-z_pyt[self.ap == 1]
        gap[~np.isfinite(gap)] = 0.0
        npeq_(z_idl[self.ap == 1],z_pyt[self.ap == 1], "Zernike Mismatch by {} +/- {}, [{},{}]".format(
            np.mean(gap), np.std(gap), np.min(gap), np.max(gap)))
            
        
    
    def test_zernike_focus(self):
        """zernike focus (2, 0)"""
        self.zernike_tests(2, 0)
        
    def test_zernike_astigmatism(self):
        """zernike astigmatism (2, +/- 2)"""
        self.zernike_tests(2, 2)
        self.zernike_tests(2, -2)
        
    def test_zernike_coma(self):
        """zernike coma (3, +/- 1)"""
        self.zernike_tests(3, 1)
        self.zernike_tests(3, -1)
        
    def test_zernike_tt(self):
        """zernike tip-tilt (1, +/- 1)"""
        self.zernike_tests(1, -1)
        self.zernike_tests(1, 1)
        
    def test_zernike_trefoil(self):
        """zernike trefoil (3, +/- 3)"""
        self.zernike_tests(3, 3)
        self.zernike_tests(3, -3)
    

class test_zernike_slopes(PIDLYTests):
    """aopy.wavefront.zernike slope functions"""
    
    
    IDL_PATHS = ["IDL/zernike/"]
    IDL_ENABLE = False
    
    def setup(self):
        """Initialize IDL"""
        super(test_zernike_slopes, self).setup()
        self.size = 40
        self.radius = 19.0
        self.circle_args = {
            'size': self.size,
            'center': self.size/2,
            'radius': self.radius,
            'value' : 1,
        }
        self.X, self.Y = np.mgrid[-self.size/2:self.size/2,-self.size/2:self.size/2] / self.radius
        self.ap = (np.sqrt(self.X**2 + self.Y**2) < 1).astype(np.int)
    
    @nt.nottest
    def zernike_slope_tests(self, n, m):
        """Zernike Mode Slope Tests"""
        zernike_args = self.circle_args
        zernike_args["n"] = n
        zernike_args["m"] = np.abs(m)
        
        z_npy = zernike.zernike_cartesian(n, m, self.X + + 0.5/self.radius, self.Y + + 0.5/self.radius)
        xs_npy, ys_npy = np.gradient(z_npy)
        xs_npy = xs_npy * self.ap * self.radius
        ys_npy = ys_npy * self.ap * self.radius
        
        xs_pyt, ys_pyt = zernike.zernike_slope_cartesian(n, m, self.X + + 0.5/self.radius, self.Y + 0.5/self.radius)
        xs_pyt = xs_pyt * self.ap
        ys_pyt = ys_pyt * self.ap
        
        filename = "{label:s}_{ident:s}_{n:d}_{m:d}.npy"
        self.POST_SAVE = [
            (xs_npy, filename.format(n=n,m=m,label="xs",ident="npy")),
            (ys_npy, filename.format(n=n,m=m,label="ys",ident="npy")),
            (xs_pyt, filename.format(n=n,m=m,label="xs",ident="pyt")),
            (ys_pyt, filename.format(n=n,m=m,label="ys",ident="pyt")),
            (z_npy,  filename.format(n=n,m=m,label="z",ident="npy")),
            ((xs_npy - xs_pyt), filename.format(n=n,m=m,label="xs",ident="dif")),
            ((ys_npy - ys_pyt), filename.format(n=n,m=m,label="ys",ident="dif")),
        ]
            
        x_gap = xs_npy[self.ap == 1] - xs_pyt[self.ap == 1]
        y_gap = ys_npy[self.ap == 1] - ys_pyt[self.ap == 1]
        
        if np.std(x_gap) > 1e-10 and np.std(y_gap) > 1e-10 and np.mean(x_gap) > 1.0 and np.mean(y_gap) > 1.0:
            npeq_(xs_npy[self.ap == 1], xs_pyt[self.ap == 1], "Zernike X-Slope Mismatch by {} +/- {} [{},{}]".format(
                np.mean(x_gap), np.std(x_gap), np.min(x_gap), np.max(x_gap), atol=0.1
            ))
            npeq_(ys_npy[self.ap == 1], ys_pyt[self.ap == 1], "Zernike Y-Slope Mismatch by {} +/- {} [{},{}]".format(
                np.mean(y_gap), np.std(y_gap), np.min(y_gap), np.max(y_gap), atol=0.1
            ))
        
    def test_zernike_slope_focus(self):
        """zernike slope focus (2, 0)"""
        self.zernike_slope_tests(2, 0)
    
    def test_zernike_slope_coma(self):
        """zernike slope coma (3, +/- 1)"""
        self.zernike_slope_tests(3, -1)
        self.zernike_slope_tests(3, 1)
    
    def test_zernike_slope_tt(self):
        """zernike slope tip-tilt (1, +/- 1)"""
        self.zernike_slope_tests(1, -1)
        self.zernike_slope_tests(1, 1)
    
    def test_zernike_slope_trefoil(self):
        """zernike slope trefoil (3, +/- 3)"""
        self.zernike_slope_tests(3, -3)
        self.zernike_slope_tests(3, 3)
        
    def test_zernike_slope_astigmatism(self):
        """zernike slope astigmatism (2, +/- 2)"""
        self.zernike_slope_tests(2, -2)
        self.zernike_slope_tests(2, 2)