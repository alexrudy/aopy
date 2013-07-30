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

def shift_phase(phase,shift):
    """docstring for shift_phase"""
    import scipy.ndimage.interpolation
    return scipy.ndimage.interpolation.shift(
        input = phase,
        shift = shift,
        order = 3, #Linear interpolation!
        mode = 'constant', #So we blank out the non-overlapping ones.
    )

ap = circle(14,15)

x_shifts, y_shifts = np.mgrid[-40:40:0.5,-40:40:0.5]
shape = x_shifts.shape
screen = ManyLayerScreen((30,30),50,vel=[2.1,3.4])
phi_a = screen.get_screen(0)
phi_b = screen.get_screen(1)
err = np.zeros(shape,dtype=np.float)
for x,y in itertools.product(*map(range,shape)):
    shift = [x_shifts[x,y],y_shifts[x,y]]
    new_phi = shift_phase(phi_a,shift)
    err[x,y] = np.log10(np.sum(np.abs(phi_b - new_phi)) / np.sum(new_phi != 0.0))
# err = np.reshape(err,x_shifts.shape)
fig = plt.figure(figsize=(6,4))
ax = fig.add_subplot(111)
ax.plot(y_shifts[81,:],err[81,:])
ax.set_xlabel(r"Shift ($v_x\; \mathrm{(m/s)}$)")
ax.set_ylabel("Error (arbitrary)")
plt.savefig("figures/GN_1d_errfunc.pdf")
fig = plt.figure()
ax = fig.add_subplot(111)
im = ax.imshow(err,interpolation='nearest',extent=[-40,40,-40,40])
ax.set_xlabel(r"$v_x\; \mathrm{(m/s)}$")
ax.set_ylabel(r"$v_y\; \mathrm{(m/s)}$")
cb = fig.colorbar(im)
cb.set_label("Error (arbitrary)")
plt.savefig("figures/GN_errfunc.pdf")