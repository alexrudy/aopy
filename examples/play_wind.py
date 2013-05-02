# -*- coding: utf-8 -*-
# 
#  play_wind.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-29.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)
import matplotlib
# matplotlib.use("Agg")
import numpy as np
from aopy.atmosphere.wind import BlowingScreen, ManyLayerScreen
import matplotlib.pyplot as plt
from matplotlib import animation
import time
from wcao.gaussnewton import estimate_wind_gn

fig = plt.figure()
ax = fig.add_subplot(111)
screen = ManyLayerScreen((50,50),30,vel=[[2.0,-3.0],[-5.0,0.0]]).setup()
im = ax.imshow(screen.get_screen(0),interpolation='nearest',vmin=-np.pi,vmax=np.pi)
ticks = np.linspace(-np.pi,np.pi,11)
cb = fig.colorbar(im,ticks=ticks)
cb.ax.set_yticklabels(map("${:.2f}\pi$".format,ticks/np.pi))
wind = np.array([0.0,0.0])
def animate(i):
    """Animate this function!"""
    ax.set_title("Phase at step %03d" % i)
    curr = screen.get_screen(i)
    im.set_data(curr)
    wind = 

anim = animation.FuncAnimation(fig, animate, frames=500, interval=20)

anim.save('movies/blowing_screen.mp4', fps=30, extra_args=['-vcodec', 'libx264'],
    writer='ffmpeg_file',
    )