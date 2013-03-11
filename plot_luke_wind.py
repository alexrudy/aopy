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
import os.path, glob

from pyshell.util import query_string, is_type_factory, check_exists
from pyshell.base import CLIEngine

def plot_histogram_binning(XY,nbins=1e2,size=None):
    """Plot a histogram binned wind map"""
    magnitude = np.sqrt(np.sum(np.power(XY,2),axis=1))
    X,Y = XY[:,0], XY[:,1]
    size = size if not size is None else np.max(magnitude)
    H, xedges, yedges = np.histogram2d(X,Y,bins=nbins,range=[[-size,size],[-size,size]])
    extent = [xedges[0], xedges[-1], yedges[0], yedges[-1] ]
    plt.imshow(H.T,extent=extent,interpolation='nearest',origin='lower')
    plt.colorbar()
    plt.ylabel("Wind Velocity (m/s)")
    plt.xlabel("Wind Velocity (m/s)")

def plot_time_series(T,XY,clip=1e3,swindow='flat',wsize=101):
    """docstring for plot_time_series"""
    assert T.shape[0] == XY.shape[0], "Shape Mismatch"
    if clip > T.shape[0]:
        clip = slice()
    else:
        clip = slice(None,clip)
    magnitude = np.sqrt(np.sum(np.power(XY,2),axis=1))
    tc = T[clip]
    xc = XY[clip,0]
    yc = XY[clip,1]
    mc = magnitude[clip]
    plt.plot(tc,xc,'g.',label="x-wind")
    plt.plot(tc,smooth(xc,wsize,window=swindow),'g-',linewidth=2.0)
    plt.plot(tc,yc,'b.',label="y-wind")
    plt.plot(tc,smooth(yc,wsize,window=swindow),'b-',linewidth=2.0)
    plt.plot(tc,mc,'r.',label='wind magnitude',zorder=0.1,alpha=0.5)
    plt.plot(tc,smooth(mc,wsize,window=swindow),'r-',linewidth=2.0,zorder=0.1,alpha=0.5)
    plt.legend()
    plt.xlabel("Time (s)")
    plt.ylabel("Wind Velocity (m/s)")

def plot_polar_map(XY,Rmax=None,Rmin=None):
    """Make a polar histogram map"""
    X, Y = XY[:,0], XY[:,1]
    R,Theta = np.sqrt(X**2.0+Y**2.0), np.arctan2(Y,X)
    if Rmax is None:
        Rmax = np.max(R)
    if Rmin is None:
        Rmin = np.min(R)+1e-14
    thedges = np.linspace(-np.pi,np.pi,100,endpoint=True)
    redges = np.linspace(np.min(R),np.max(R),100,endpoint=True)
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
    plt.colorbar()
    plt.xlabel("Wind Velocity (m/s)")
    plt.gca().tick_params(axis='x', colors='w')
    
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

def select_files(files,allow_all=True):
    """docstring for select_files"""
    print "Select file to examine:"
    if allow_all:
        print "{:>3d}) {:s}".format(0,"all")
    for i,filename in enumerate(files):
        print "{:>3d}) {:s}".format(i+1,filename)
    value = int(query_string("Select File:",default=0,validate=is_type_factory(int))) - 1
    if allow_all and value == -1:
        return files
    else:
        return [files[value]]

class PlotLukeWind(CLIEngine):
    """docstring for PlotLukeWind"""
    defaultcfg = False
    module = __name__
    
    def configure(self):
        """Initialize un-configured arguments"""
        super(PlotLukeWind, self).configure()
        self.parser.add_argument("name",help="File name or index",action='store',nargs="*")
        
        
        
    def do(self):
        """Take action!"""
        files = glob.glob("data/**/proc/*_wind.fits")
        if len(self.opts.name) == 0:
            self.opts.name = select_files(files)
        if len(self.opts.name) == 1 and is_type_factory(int)(self.opts.name[0]) and int(self.opts.name[0]) == 0:
            self.opts.name = files
        FileNames = []
        for fname in self.opts.name:
            if is_type_factory(int)(fname):
                FileNames.append(files[fname])
            elif isinstance(fname,basestring) and check_exists(fname):
                FileNames.append(fname)
            else:
                print("Skipping File '{}'".format(fname))
        
        print("Examining:\n -{}".format("\n -".join(FileNames)))
        Methods = ['GN','RT','2D','XY']
        
        for FileName in FileNames:
            BaseName = os.path.splitext(os.path.basename(FileName))[0]
            InstName = FileName.split("/")[1]
            OBaseName = os.path.join("figures","{type}_{method}_{tel}_{set}.{ext}")
            OBaseDict = {
                'tel' : InstName,
                'set' : "_".join(BaseName.split("_")[:-1]),
                'set_tex' : "\\verb+{}+".format("_".join(BaseName.split("_")[:-1])),
                'ext' : "png"
            }

            DataFile = pf.open(FileName)
            for Method in range(len(Methods)):
                WIND = DataFile[0].data[:,:2,Method]
                TIME = DataFile[0].data[:,2,Method]
                clip = 2e3
                OBaseDict["method"] = Methods[Method]
                print("Plotting {method} for {tel} during '{set}'".format(**OBaseDict))    
                plot_polar_map(WIND)
                plt.title("Polar Map of wind from {method} method at {tel} for '{set_tex}'".format(**OBaseDict))
                plt.savefig(OBaseName.format(type="polarmap",**OBaseDict))
                plt.clf()
                plot_time_series(TIME,WIND)
                plt.title("Time Series wind from {method} method at {tel} for '{set_tex}'".format(**OBaseDict))
                plt.savefig(OBaseName.format(type="timeseries",**OBaseDict))
                plt.clf()
                plot_histogram_binning(WIND)
                plt.title("Wind Velocitiy Histogram from {method} method at {tel} for '{set_tex}'".format(**OBaseDict))
                plt.savefig(OBaseName.format(type="histogram",**OBaseDict))
                plt.clf()
                
if __name__ == '__main__':
    PlotLukeWind.script()
    