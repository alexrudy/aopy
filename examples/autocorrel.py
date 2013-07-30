#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  minphaseshift.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-07-25.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

"""
Show the total phase error as a function of subaperture shifts.
"""

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)
import matplotlib
import numpy as np
from aopy.atmosphere.wind import BlowingScreen, ManyLayerScreen
from aopy.util.math import depiston, circle
import matplotlib.pyplot as plt
from matplotlib import animation
import time, itertools

from scipy.signal import fftconvolve

screen = ManyLayerScreen((30,30),50,vel=[2.0,3.0])
phi_a = screen.get_screen(0)
phi_b = screen.get_screen(1)

corr = fftconvolve(phi_a,-1*phi_b,mode='full')

# corr = -1*np.log10corr
fig = plt.figure()
ax = fig.add_subplot(111)
im = ax.imshow(corr,interpolation='nearest',extent=[-1*corr.shape[0],corr.shape[0],-1*corr.shape[1],corr.shape[1]])
ax.set_xlabel(r"$v_x\; \mathrm{(m/s)}$")
ax.set_ylabel(r"$v_y\; \mathrm{(m/s)}$")
cb = fig.colorbar(im)
cb.set_label("Error (arbitrary)")
plt.savefig("figures/GN_correl.pdf")