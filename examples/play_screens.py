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

SAVE_ANIM = True

fig = plt.figure()
ax = fig.add_subplot(111)
screen = ManyLayerScreen((50,50),30,vel=[2.0,-3.0]).setup()
im = ax.imshow(screen.get_screen(0),interpolation='nearest',vmin=-np.pi,vmax=np.pi)
ap = circle(14,15)
ticks = np.linspace(-np.pi,np.pi,11)
cb = fig.colorbar(im,ticks=ticks)
cb.ax.set_yticklabels(map(r"${:.2f}\pi$".format,ticks/np.pi))

def animate(i):
    """Animate this function!"""
    curr = screen.get_screen(i)
    ax.set_title("Phase at step %03d [%g,%g]" % (i,np.min(curr),np.max(curr)))
    im.set_data(depiston(curr))
    cb.update_normal(im)
    cb.ax.set_yticklabels(map(r"${:.2f}\pi$".format,ticks/np.pi))
    

# ims = []
# for i in range(500):
#     ims.append([plt.imshow(depiston(screen.get_screen(i)),vmin=-np.pi,vmax=np.pi)])

# anim = animation.ArtistAnimation(fig, ims, interval=20)
anim = animation.FuncAnimation(fig, animate, frames=500, interval=20)

if SAVE_ANIM:
    anim.save('movies/blowing_screen_1l.mp4', fps=30, extra_args=['-vcodec', 'libx264'],
        writer='ffmpeg_file',
        )
else:
    plt.show()

