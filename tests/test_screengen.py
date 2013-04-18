# -*- coding: utf-8 -*-
# 
#  test_screengen.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-12.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 

from ..aopy import screengen

import numpy as np

class test_Screen(object):
    """Screen"""
    
    
    def test_filter_creation(self):
        """docstring for test_filter_creation"""
        args = {
            'n': 30,
            'm': 30,
            'r0': 4,
            'du': 2,
        }
        import pidly
        IDL = pidly.IDL()
        IDL('!PATH=!PATH+":"+expand_path("+~/Development/IDL/don_pro")')
        IDL('f = screengen({n:d},{m:d},{r0:f},{du:f})'.format(**args))
        f_don = IDL.f
        
        f_alex = screengen.Screen((args['n'],args['m'])).generate_filter(args['r0'],args['du'])
        
        assert np.allclose(f_don,f_alex)
        