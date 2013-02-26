#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  plot_luke_wind.py
#  telem_analysis_13
#  
#  Created by Jaberwocky on 2013-02-21.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
from __future__ import division
import matplotlib.pyplot as plt
import numpy as np
import pyfits as pf
def smooth(x,window_len=11,window='hanning'):
        if x.ndim != 1:
                raise ValueError, "smooth only accepts 1 dimension arrays."
        if x.size < window_len:
                raise ValueError, "Input vector needs to be bigger than window size."
        if window_len<3:
                return x
        if not window in ['flat', 'hanning', 'hamming', 'bartlett', 'blackman']:
                raise ValueError, "Window is on of 'flat', 'hanning', 'hamming', 'bartlett', 'blackman'"
        s=np.r_[2*x[0]-x[window_len-1::-1],x,2*x[-1]-x[-1:-window_len:-1]]
        if window == 'flat': #moving average
                w=np.ones(window_len,'d')
        else:  
                w=getattr(np,window)(window_len)
        y=np.convolve(w/w.sum(),s,mode='same')
        return y[window_len:-window_len+1]
        
DataFile = pf.open("processed_GN_wind.fits")
WIND = DataFile[0].data
WINDSQ = np.power(WIND,2)
WINDMAG = np.sqrt(WINDSQ[:,0]+WINDSQ[:,1])
TIME = np.arange(WIND.shape[0])
clip = 2e3
plt.plot(TIME[:clip],WIND[:clip,0],'g.',label="x-wind")
plt.plot(TIME[:clip],smooth(WIND[:clip,0],101,window='flat'),'g-',linewidth=2.0)
plt.plot(TIME[:clip],WIND[:clip,1],'b.',label="y-wind")
plt.plot(TIME[:clip],smooth(WIND[:clip,1],101,window='flat'),'b-',linewidth=2.0)
plt.plot(TIME[:clip],WINDMAG[:clip],'r.',label='wind magnitude',zorder=0.1)
plt.plot(TIME[:clip],smooth(WINDMAG[:clip],101,window='flat'),'r-',linewidth=2.0,zorder=0.1)

plt.legend()
plt.xlabel("Time (s)")
plt.ylabel("Wind Velocity (m/s)")
plt.title("Wind Estimation for Keck-0 with Gauss-Newton Method")
plt.savefig("GN-Wind.png")

plt.clf()
plt.plot(WIND[:clip,0],WIND[:clip,1],'.')
plt.axis('equal')
plt.savefig("GN-WindMap.png")
plt.clf()
dist = 10
H, xedges, yedges = np.histogram2d(WIND[:,0],WIND[:,1],bins=100,range=[[-dist,dist],[-dist,dist]])
extent = [xedges[0], xedges[-1], yedges[0], yedges[-1] ]
plt.imshow(H.T,extent=extent,interpolation='nearest',origin='lower')
plt.colorbar()
plt.title("Wind Velocity Density Map")
plt.ylabel("Wind Velocity (m/s)")
plt.xlabel("Wind Velocity (m/s)")
plt.savefig("GN-WindMap-Bin.png")
