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

from pyshell.util import remove
import pidly

from .util import npeq_

from aopy.aperture.slopemanage import slope_management

class test_slopemanage(object):
    """aopy.aperture.slopemanage"""
    
    
    def setup(self):
        """Initialize IDL"""
        
        IDL_PATH = os.path.normpath(os.path.join(os.path.dirname(__file__),"../IDL/poyneer/"))
        IDL_Library = os.path.normpath(os.path.join(os.path.dirname(__file__),"../IDL/library/"))
        self.idl_output = True
        self.size = 40
        self.radius = 19.0
        self.circle_args = {
            'size': self.size,
            'center': self.size/2,
            'radius': self.radius,
            'value' : 1.0,
        }
        self.IDL = pidly.IDL()
        self.IDL('!PATH=expand_path("<IDL_default>")+":"+expand_path("+{:s}")+":"+expand_path("+{:s}")'.format(IDL_PATH,IDL_Library),
            print_output=self.idl_output)
        self.IDL('.compile slope_management.pro',print_output=self.idl_output)
        self.IDL('ap = circle({size},{size},{center},{center},{radius},{value})'.format(
            ** self.circle_args
        ), print_output=self.idl_output)
        self.ap = self.IDL.ap
    
    def teardown(self):
        """Teardown IDL"""
        self.IDL.close()

    def test_idl_focus_slopes(self):
        """agreement with idl focus slopes"""
        n = 2
        m = 0
        self.IDL('generate_grids, x, y, {size}'.format(size=self.size))
        self.IDL('xs = x * ap')
        self.IDL('ys = y * ap')
        xs = self.IDL.xs.T
        ys = self.IDL.ys.T
        self.IDL('slope_management, ap, xs, ys')
        xs_idl = self.IDL.xs.T
        ys_idl = self.IDL.ys.T
        xs_pyt, ys_pyt = slope_management(self.ap, xs, ys)
        
        idl_filename = "zs_sm_idl_{n:d}_{m:d}.npy".format(n=n,m=m)
        pyt_filename = "zs_sm_pyt_{n:d}_{m:d}.npy".format(n=n,m=m)
        np.savetxt("y_idl.txt",self.IDL.y.T)
        np.savetxt("yz_idl.txt",ys)
        np.savetxt("yz_sm_idl.txt",ys_idl)
        
        self.compare_slopes(xs_idl, xs_pyt, ys_idl, ys_pyt, idl_filename, pyt_filename)
        
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
        