# -*- coding: utf-8 -*-
# 
#  fft.py
#  aopy
#  
#  Created by Jaberwocky on 2013-10-30.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
"""
:mod:`fft` - Tools for Fast Fourier Transforms
==============================================

"""

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np

def fftishift(i, n=None):
    """Shift an FFT index, or an array of fft indicies.
    
    Goes from ``i`` to ``k``
    """
    if n is None:
        n = i.shape[0]
    p2 = (n+1)//2
    kvalues = np.concatenate((np.arange(p2, n), np.arange(p2)))
    return kvalues[i]
    
def ifftishift(k, n=None):
    """Reverse-shift an FFT index, or an array of fft indicies.
    
    Goes from ``k`` to ``i``
    """
    if n is None:
        n = k.shape[0]
    p2 = n-(n+1)//2
    ivalues = np.concatenate((np.arange(p2, n), np.arange(p2)))
    return ivalues[k]