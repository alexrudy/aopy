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
import os.path

def plot_polar_map(X,Y,nbins=1e3,Rmax=None):
    """Make a polar histogram map"""
    R,Theta = np.sqrt(X**2.0+Y**2.0), np.arctan2(Y,X)
    if Rmax is None:
        Rmax = np.max(R)
    thedges = np.linspace(-np.pi,np.pi,100,endpoint=True)
    redges = np.concatenate((np.array([0]),np.logspace(np.log(np.min(R)),np.log(Rmax),99,endpoint=True)))
    H, thedges, redges  = np.histogram2d(Theta,R,bins=[thedges,redges])
    thcoords, rcoords = np.meshgrid(thedges,redges)
    dthetas = thedges[1:] - thedges[:-1]
    drs     = np.abs(np.power(redges[1:],2.0) - np.power(redges[:-1],2.0))
    dthetas, drs = np.meshgrid(dthetas,drs)
    areas   = 0.5 * dthetas * drs
    wH = H / np.log(areas.T)
    
    # print u"θ=",np.max(thcoords)/np.pi,u"π",u" , ",np.min(thcoords)/np.pi,u"π"
    plt.axes(polar=True)
    plt.pcolormesh(thcoords,rcoords,H.T)
    
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

FileName = "data/keck/proc/20070730_2_wind.fits"
# FileName = "data/altair/proc/20070417_wind.fits"
Method = 0
Methods = ['GN','RT','2D','XY']
BaseName = os.path.splitext(os.path.basename(FileName))[0]
InstName = FileName.split("/")[1]
OBaseName = os.path.join("figures",InstName+"-"+BaseName+"-"+Methods[Method])
DataFile = pf.open(FileName)
WIND = DataFile[0].data[:,:,Method]
WINDSQ = np.power(WIND,2)
WINDX = WIND[:,0]
WINDY = WIND[:,1]
WINDMAG = np.sqrt(WINDSQ[:,0]+WINDSQ[:,1])
TIME = WIND[:,2]
clip = 2e3
plt.plot(TIME[:clip],WINDX[:clip],'g.',label="x-wind")
plt.plot(TIME[:clip],smooth(WINDX[:clip],101,window='flat'),'g-',linewidth=2.0)
plt.plot(TIME[:clip],WINDY[:clip],'b.',label="y-wind")
plt.plot(TIME[:clip],smooth(WINDY[:clip],101,window='flat'),'b-',linewidth=2.0)
plt.plot(TIME[:clip],WINDMAG[:clip],'r.',label='wind magnitude',zorder=0.1,alpha=0.5)
plt.plot(TIME[:clip],smooth(WINDMAG[:clip],101,window='flat'),'r-',linewidth=2.0,zorder=0.1,alpha=0.5)

plt.legend()
plt.xlabel("Time (s)")
plt.ylabel("Wind Velocity (m/s)")
plt.title("Wind Estimation for Keck-0 with Gauss-Newton Method")
plt.savefig(OBaseName+"-Timeseries.png")

plt.clf()
plt.plot(WIND[:clip,0],WIND[:clip,1],'.')
plt.axis('equal')
plt.savefig(OBaseName+"-ScatterPlot.png")
plt.clf()

dist = np.max(WINDMAG)
H, xedges, yedges = np.histogram2d(WIND[:,0],WIND[:,1],bins=100,range=[[-dist,dist],[-dist,dist]])
extent = [xedges[0], xedges[-1], yedges[0], yedges[-1] ]
plt.imshow(H.T,extent=extent,interpolation='nearest',origin='lower')
plt.colorbar()
plt.title("Wind Velocity Density Map")
plt.ylabel("Wind Velocity (m/s)")
plt.xlabel("Wind Velocity (m/s)")
plt.savefig(OBaseName+"-WindMap-XY.png")

plot_polar_map(WINDX,WINDY,Rmax=dist)
plt.grid(color='w')
plt.colorbar()
plt.xlabel("Wind Velocity (m/s)")
plt.gca().tick_params(axis='x', colors='w')
plt.savefig(OBaseName+"-PolarMap.png")
plt.clf()
plot_polar_map(smooth(WINDX,11,window='flat'),smooth(WINDY,11,window='flat'),Rmax=dist)
plt.gca().spines['polar'].set_color('w')
plt.grid(color='w')
plt.xlabel("Wind Velocity (m/s)")
plt.gca().tick_params(axis='x', colors='w')
plt.colorbar()
plt.savefig(OBaseName+"-BinPolarMap.png")

print OBaseName

