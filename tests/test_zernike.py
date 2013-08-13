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
        z_idl = self.IDL.z * self.ap
        
        z_pyt = zernike.zernike_cartesian(n, m, self.X, self.Y) * self.ap * np.sqrt(n+1)
        
        np.savetxt("z_idl.dat",z_idl)
        np.savetxt("z_pyt.dat",z_pyt)
        gap = z_idl[self.ap == 1]-z_pyt[self.ap == 1]
        gap[~np.isfinite(gap)] = 0.0
        npeq_(z_idl[self.ap == 1],z_pyt[self.ap == 1], "Zernike Mismatch by {} +/- {}, [{},{}]".format(
            np.mean(gap), np.std(gap), np.min(gap), np.max(gap)))
    
    def test_zernike_focus(self):
        """zernike focus (2, 0)"""
        self.zernike_tests(2, 0)
        
    def test_zernike_coma(self):
        """zernike coma (+/- 1, 3)"""
        self.zernike_tests(1, 3)
        self.zernike_tests(-1, 3)
        

        