#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  play_screens.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-04-16.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
from __future__ import division
import matplotlib
# matplotlib.use("Agg")
import numpy as np
from aopy.atmosphere.wind import BlowingScreen, ManyLayerScreen
from aopy.util.math import depiston, circle
import matplotlib.pyplot as plt
from matplotlib import animation
import time


fig = plt.figure()
ax = fig.add_subplot(111)
screen = ManyLayerScreen((30,30),50,vel=[[2.0,-3.0],[0.0,0.0]],strength=[0.8,0.2]).setup()
ap = circle(14,15)
im = ax.imshow(screen.get_screen(0)*ap,interpolation='nearest',vmin=-np.pi,vmax=np.pi)
ticks = np.linspace(-np.pi,np.pi,11)
cb = fig.colorbar(im,ticks=ticks)
cb.ax.set_yticklabels(map(r"${:.2f}\pi$".format,ticks/np.pi))

fig.savefig("figures/phase_a.pdf")

ax.imshow(screen.get_screen(1)*ap,interpolation='nearest',vmin=-np.pi,vmax=np.pi)

fig.savefig("figures/phase_b.pdf")