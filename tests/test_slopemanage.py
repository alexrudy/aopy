# -*- coding: utf-8 -*-
# 
#  test_slopemanage.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-08-14.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)
import nose.tools as nt
import numpy as np

import os, os.path

import pidly

from .util import npeq_, PIDLYTests, npeq_or_save

from aopy.wavefront import zernike
from aopy.aperture.slopemanage import slope_management

class test_slopemanage(PIDLYTests):
    """aopy.aperture.slopemanage"""
    
    IDL_PATHS = ["IDL/poyneer/"]
    IDL_OUTPUT = True
    
    def setup(self):
        """Initialize IDL"""
        super(test_slopemanage, self).setup()
        self.size = 40
        self.radius = 19.0
        self.circle_args = {
            'size': self.size,
            'center': self.size/2,
            'radius': self.radius,
            'value' : 1.0,
        }
        self.IDL('.compile slope_management.pro',print_output=self.IDL_OUTPUT)
        self.IDL('ap = circle({size},{size},{center},{center},{radius},{value})'.format(
            ** self.circle_args
        ), print_output=self.IDL_OUTPUT)
        self.idl_ap = self.IDL.ap
        n = self.size
        self.Xs, self.Ys = np.mgrid[-n:n,-n:n] / self.radius
        self.X, self.Y = np.mgrid[-n:n,-n:n]
        self.ap = (np.sqrt(self.X**2.0 + self.Y**2.0) < self.radius).astype(np.int)
    
    def test_idl_focus_slopes(self):
        """idl focus slopes"""
        n = 2
        m = 0
        self.IDL('generate_grids, x, y, {size}'.format(size=self.size))
        self.IDL('xs = x * ap')
        self.IDL('ys = y * ap')
        ys = self.IDL.xs.T
        xs = self.IDL.ys.T
        self.IDL('slope_management, ap, xs, ys')
        xs_idl = self.IDL.ys.T
        ys_idl = self.IDL.xs.T
        xs_pyt, ys_pyt = slope_management(self.idl_ap, xs, ys)
        
        idl_filename = "s_sm_IDL_idl_{n:d}_{m:d}.npy".format(n=n,m=m)
        pyt_filename = "s_sm_IDL_pyt_{n:d}_{m:d}.npy".format(n=n,m=m)
        
        x_result = npeq_or_save(xs_idl, xs_pyt, a_name="x"+idl_filename, b_name="x"+pyt_filename)
        y_result = npeq_or_save(ys_idl, ys_pyt, a_name="y"+idl_filename, b_name="y"+pyt_filename)
        nt.ok_(x_result and y_result, "Slope Mismatch")
        
        
    def test_focus_slopes(self):
        """focus slopes"""
        self.python_slopes(2, 0)
        
    def test_tiptilt_slopes(self):
        """tip/tilt slopes"""
        self.python_slopes(1, -1)
        self.python_slopes(1, 1)
        
    @nt.nottest
    def python_slopes(self, n, m):
        """Run a test of a set of python slopes."""
        xs_pyt, ys_pyt = zernike.zernike_slope_cartesian(n, m, self.Xs + + 0.5/self.radius, self.Ys + 0.5/self.radius)
        xs_pyt = xs_pyt * self.ap
        ys_pyt = ys_pyt * self.ap
        self.IDL.xs = ys_pyt.T
        self.IDL.ys = xs_pyt.T
        self.IDL.ap = self.ap
        self.IDL('slope_management, ap, xs, ys')
        self.IDL('xs_sm = ys')
        self.IDL('ys_sm = xs')
        xs_idl = self.IDL.xs_sm.T
        ys_idl = self.IDL.ys_sm.T
        xs_pyt, ys_pyt = slope_management(self.ap, xs_pyt, ys_pyt)
        
        idl_filename = "s_sm_idl_{n:d}_{m:d}.npy".format(n=n,m=m)
        pyt_filename = "s_sm_pyt_{n:d}_{m:d}.npy".format(n=n,m=m)
        
        x_result = npeq_or_save(xs_idl, xs_pyt, a_name="x"+idl_filename, b_name="x"+pyt_filename)
        y_result = npeq_or_save(ys_idl, ys_pyt, a_name="y"+idl_filename, b_name="y"+pyt_filename)
        nt.ok_(x_result and y_result, "Slope Mismatch")
        
        
    @nt.nottest
    def compare_slopes(self, xs_a, xs_b, ys_a, ys_b, fn_a, fn_b):
        """Compare Slopes"""
        valid = np.allclose(xs_a, xs_b) and np.allclose(ys_a, ys_b)
        
        if not valid:
            np.save(fn_a, np.dstack((xs_a, ys_a)))
            np.save(fn_b, np.dstack((xs_b, ys_b)))
        else:
            remove(fn_a)
            remove(fn_b)
        
        npeq_(xs_a, xs_b, "X Slope Mismatch")
        npeq_(ys_a, ys_b, "Y Slope Mismatch")
        