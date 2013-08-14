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
import numpy as np

import os, os.path

from pyshell.util import remove
import pidly

from .util import npeq_

from aopy.wavefront import zernike

class test_zernike_polynomials(object):
    """aopy.wavefront.zernike functions"""
    
    def setup(self):
        """Initialize IDL"""
        
        IDL_PATH = os.path.normpath(os.path.join(os.path.dirname(__file__),"../IDL/zernike/"))
        self.idl_output = True
        self.size = 40
        self.radius = 19
        self.circle_args = {
            'size': self.size,
            'center': self.size/2,
            'radius': self.radius,
            'value' : 1,
        }
        self.IDL = pidly.IDL()
        self.IDL('!PATH=expand_path("<IDL_default>")+":"+expand_path("+{:s}")'.format(IDL_PATH),print_output=self.idl_output)
        self.IDL('.compile zernike.pro',print_output=self.idl_output)
        self.IDL('ap = circle({size},{size},{center},{center},{radius},{value})'.format(
            ** self.circle_args
        ), print_output=self.idl_output)
        self.X, self.Y = np.mgrid[-self.size/2:self.size/2,-self.size/2:self.size/2] / self.radius
        self.ap = (np.sqrt(self.X**2 + self.Y**2) < 1).astype(np.int)
    
    def teardown(self):
        """Teardown IDL"""
        self.IDL.close()
    
    @nt.nottest
    def zernike_tests(self, n, m):
        """Zernike Mode Tests"""
        zernike_args = self.circle_args
        zernike_args["n"] = n
        zernike_args["m"] = m
        self.IDL('z = zernike({size},{size},{radius},{n},{m},/noll)'.format(**zernike_args), print_output=self.idl_output)
        z_idl = self.IDL.z.T * self.ap
        
        z_pyt = zernike.zernike_cartesian(n, m, self.X, self.Y) * self.ap
        
        idl_filename = "z_idl_{n:d}_{m:d}.dat".format(n=n,m=m)
        pyt_filename = "z_pyt_{n:d}_{m:d}.dat".format(n=n,m=m)
        if not np.allclose(z_idl, z_pyt, atol=1e-5):
            np.savetxt(idl_filename,z_idl)
            np.savetxt(pyt_filename,z_pyt)
        else:
            remove(idl_filename)
            remove(pyt_filename)
        
        gap = z_idl[self.ap == 1]-z_pyt[self.ap == 1]
        gap[~np.isfinite(gap)] = 0.0
        npeq_(z_idl[self.ap == 1],z_pyt[self.ap == 1], "Zernike Mismatch by {} +/- {}, [{},{}]".format(
            np.mean(gap), np.std(gap), np.min(gap), np.max(gap)))
            
    @nt.nottest
    def zernike_slope_tests(self, n, m):
        """Zernike Mode Slope Tests"""
        zernike_args = self.circle_args
        zernike_args["n"] = n
        zernike_args["m"] = np.abs(m)
        self.IDL('z_s = zernikeslope({size}, {size}, {radius:d}, {n:d}, {m:d})'.format(**zernike_args))
        self.IDL('x_s = real_part(z_s[0:39,*])')
        self.IDL('y_s = real_part(z_s[40:79,*])')
        # if m < 0:
        #     ys_idl, xs_idl = self.IDL.x_s, self.IDL.y_s
        # else:
        xs_idl, ys_idl = self.IDL.x_s, self.IDL.y_s
        xs_idl = xs_idl.T * self.ap
        ys_idl = ys_idl.T * self.ap
        
        xs_pyt, ys_pyt = zernike.zernike_slope_cartesian(n, m, self.X, self.Y)
        xs_pyt = xs_pyt * self.ap
        ys_pyt = ys_pyt * self.ap
        
        idl_filename = "zs_idl_{n:d}_{m:d}.npy".format(n=n,m=m)
        pyt_filename = "zs_pyt_{n:d}_{m:d}.npy".format(n=n,m=m)
        
        if not (np.allclose(xs_pyt, xs_idl, atol=1e-5) and np.allclose(ys_pyt, ys_idl, atol=1e-5)):
            np.save(idl_filename, np.dstack((xs_idl, ys_idl)))
            np.save(pyt_filename, np.dstack((xs_pyt, ys_pyt)))
        else:
            remove(idl_filename)
            remove(pyt_filename)
            
        x_gap = xs_idl[self.ap == 1] - xs_pyt[self.ap == 1]
        y_gap = ys_idl[self.ap == 1] - ys_pyt[self.ap == 1]
        
        npeq_(xs_idl[self.ap == 1], xs_pyt[self.ap == 1], "Zernike X-Slope Mismatch by {} +/- {} [{},{}]".format(
            np.mean(x_gap), np.std(x_gap), np.min(x_gap), np.max(x_gap)
        ))
        npeq_(ys_idl[self.ap == 1], ys_pyt[self.ap == 1], "Zernike Y-Slope Mismatch by {} +/- {} [{},{}]".format(
            np.mean(y_gap), np.std(y_gap), np.min(y_gap), np.max(y_gap)
        ))
    
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

        