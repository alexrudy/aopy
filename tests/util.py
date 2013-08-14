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

import numpy as np

def npeq_(a,b,msg, rtol=1e-8, atol=1e-4):
    """Assert numpy equal"""
    nt.ok_(np.allclose(a,b,rtol=rtol, atol=atol),"{:s} {!s}!={!s}".format(msg,a,b))
