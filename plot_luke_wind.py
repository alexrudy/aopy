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
import matplotlib.cm as cm
import numpy as np
import pyfits as pf
import os.path, glob
import scipy.ndimage

from pyshell.util import query_string, is_type_factory, check_exists
from pyshell.base import CLIEngine

def make_hist(X,Y,Z=None,nbins=1e3,size=None):
    """docstring for make_hist"""
    XY = np.vstack((X,Y))
    magnitude = np.sqrt(np.sum(np.power(XY,2),axis=0))
    if Z is None:
        Z = np.ones(X.shape)
    size = size if not size is None else np.max(magnitude)
    H, xedges, yedges = np.histogram2d(X.flatten(),Y.flatten(),bins=nbins,range=[[-size,size],[-size,size]],weights=Z.flatten())
    extent = [xedges[0], xedges[-1], yedges[0], yedges[-1] ]
    return H, xedges, yedges, extent

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

def plot_time_series(T,XY,clip=5e3,swindow='flat',whz=1):
    """docstring for plot_time_series"""
    assert T.shape[0] == XY.shape[0], "Shape Mismatch"
    if clip > T.shape[0]:
        clip = slice()
    else:
        clip = slice(None,clip)
    magnitude = np.sqrt(np.sum(np.power(XY,2),axis=1))
    tstep = np.mean(np.diff(T))
    wsize = (1.0 / tstep) / whz
    tc = T[clip]
    xc = XY[clip,0]
    yc = XY[clip,1]
    mc = magnitude[clip]
    plt.plot(tc,xc,'gx',label="x-wind")
    plt.plot(tc,smooth(xc,wsize,window=swindow),'g-',linewidth=2.0)
    plt.plot(tc,yc,'bx',label="y-wind")
    plt.plot(tc,smooth(yc,wsize,window=swindow),'b-',linewidth=2.0)
    plt.plot(tc,mc,'rx',label='wind magnitude',zorder=0.1,alpha=0.5)
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
        
def strip_filename(filename):
    """Strip a filename to its base for this system"""
    return "_".join(filename.split("_")[:-1])
    
class _WindPredictionMethod(object):
    """A simple namespace for wind prediction algorithms"""
    phase_names = ['GN','RT','2D','XY']
    fourier_names = ['FT']
    longnames = {
        'GN' : "Gauss Newton",
        'RT' : "Radon Transform",
        '2D' : "2D Binary Search",
        'XY' : "Split 2D Binary Search",
        'FT' : "Time-Domain Fourier Transform",
    }
    nbins = {
        'GN' : 51,
        'RT' : 51,
        '2D' : 51,
        'XY' : 51,
        'FT' : 161,
    }
    
    def __init__(self,name,**kwargs):
        super(_WindPredictionMethod, self).__init__()
        self.__dict__.update(kwargs)
        self.name = name
        if self.name not in self.longnames:
            raise AttributeError("Unkown Method!")
        
    def istimeseries(self):
        """Check if this is a timeseries dataset."""
        return self.name in self.phase_names
        
    @property
    def longname(self):
        """The long name for this method"""
        return self.longnames[self.name]
        
    def luke_data(self,clip=None):
        """Return Luke's simulation data"""
        if self.name == "GN":
            X = self.lfile[0].data[:,1]
            Y = -1 * self.lfile[0].data[:,0]
            return self.clip(clip,X,Y)
        else:
            return False
        
    def data(self,mode='raw',**kwargs):
        """docstring for data"""
        return getattr(self,mode+'_data')(**kwargs)
        
    def raw_data(self,clip=None,**kwargs):
        """Get data from a pyfits instance"""
            
        if self.name in self.phase_names:
            i = self.phase_names.index(self.name)
            X = self.pfile[0].data[:,1,i]
            Y = self.pfile[0].data[:,0,i]
            Z = self.pfile[0].data[:,2,i]
        elif self.name in self.fourier_names:
            Z = self.ffile[0].data.T
            x = -1 * self.ffile[1].data
            y = -1 * self.ffile[2].data
            X,Y = np.meshgrid(x,y)
        X,Y,Z = self.clip(clip,X,Y,Z)
        return X,Y,Z
    
    def clip(self,clip,*args):
        """docstring for clip"""
        if clip is None:
            return [ np.asarray(arg) for arg in args ]
        if isinstance(clip,int):
            clip = slice(None,clip)
        return [ np.asarray(arg)[clip] for arg in args ]
    
    def smoothed_data(self,time=0.1,clip=None,**kwargs):
        """Time-series smooth data"""
        if not self.istimeseries():
            # We can't smooth non-timeseries data
            return self.raw_data(**kwargs)
        X,Y,T = self.raw_data(**kwargs)
        tstep = np.mean(np.diff(T))
        wsize = np.round(time / tstep,0)
        Xs = smooth(X,wsize,'flat')
        Ys = smooth(Y,wsize,'flat')
        return self.clip(clip,Xs,Ys,T)
        
    
    def normalized_data(self,nbins=None,mode='raw',clip=None,**kwargs):
        """Get the normalized data, binned to the appropriate level"""
        if nbins is None:
            nbins = self.nbins[self.name]
        if self.name in self.phase_names:
            X,Y,T = self.data(mode=mode,**kwargs)
            H, xedges, yedges, extent = make_hist(X,Y,nbins=nbins,size=40)
        elif self.name in self.fourier_names:
            X,Y,Z = self.data(mode=mode,**kwargs)
            H, xedges, yedges, extent = make_hist(X,Y,Z,nbins=nbins,size=40)
        self.H = H
        self.x = xedges
        self.y = yedges
        self.extent = extent
        return H, xedges, yedges, extent
        
    def com(self):
        """Return the (x,y) position of the centered data"""
        x,y = scipy.ndimage.measurements.center_of_mass(self.H)
        return self.y[y], self.x[x]
        
    def max(self):
        """Return the (x,y) position of the maximum coordinate"""
        arg = np.argmax(self.H)
        x,y = np.unravel_index(arg,self.H.shape)
        return self.y[y], self.x[x]

class PlotLukeWind(CLIEngine):
    """docstring for PlotLukeWind"""
    defaultcfg = "windplots.yml"
    module = __name__
    
    def configure(self):
        """Initialize un-configured arguments"""
        super(PlotLukeWind, self).configure()
        self.parser.add_argument("name",help="File name or index",action='store',nargs="*")
        self.methods = {}
        methods = ['GN','RT','2D','XY','FT']
        for meth in methods:
            self.methods[meth] = _WindPredictionMethod(name=meth)
        self.limits = (self.config["Maps.Limits.min"],self.config["Maps.Limits.max"])
        
        
    def do(self):
        """Take action!"""
        files = glob.glob("data/**/proc/*_phase.fits")
        if len(self.opts.name) == 0:
            self.opts.name = select_files(files)
        if len(self.opts.name) == 1 and is_type_factory(int)(self.opts.name[0]) and int(self.opts.name[0]) == 0:
            self.opts.name = files
        FileNames = []
        for fname in self.opts.name:
            if is_type_factory(int)(fname):
                FileNames.append(strip_filename(files[int(fname)-1]))
            elif isinstance(fname,basestring) and check_exists(fname):
                FileNames.append(strip_filename(fname))
            else:
                print("Skipping File '{}'".format(fname))
        
        print("Examining:\n -'{}'".format("'\n -'".join(FileNames)))
        
        for method in self.methods:
            self.methods[method].figures = {}
            self.methods[method].figures["map"] = plt.figure()
            self.methods[method].figures["map"].add_subplot(1,1,1)
            self.methods[method].figures["timeseries"] = plt.figure()
            self.methods[method].figures["timeseries"].add_subplot(3,1,1)
            self.methods[method].figures["timeseries"].add_subplot(3,1,2)
            self.methods[method].figures["timeseries"].add_subplot(3,1,3)
            self.methods[method].tst = self.methods[method].figures["timeseries"].suptitle("Title")
            self.methods[method].figures["bintest"] = plt.figure()
            self.methods[method].figures["bintest"].add_subplot(1,1,1)
        
        for FileName in FileNames:
            BaseName   = os.path.splitext(os.path.basename(FileName))[0]
            Instrument = FileName.split("/")[1]
            FigureName = os.path.join("figures","{type}_{method}_{tel}_{set}.{ext}")
            FigureDict  = {
                'tel' : Instrument,
                'tel_tex' : Instrument.replace("_"," "),
                'set' : BaseName,
                'set_tex' : r"\verb+{}+".format(BaseName),
                'ext' : "png"
            }
            CWMapFile = pf.open(FileName+'_wind.fits')
            FWMapFile = pf.open(FileName+'_fwmap.fits')
            if check_exists(FileName+'_luke_wind.fits'):
                LWMapFile = pf.open(FileName+'_luke_wind.fits')
            else:
                LWMapFile = False
            cfig = plt.figure(dpi=self.config["Figures.DPI"])
            cfig.add_subplot(1,1,1)
            for method in ["GN","2D","XY","FT"]:
                M = self.methods[method]
                FigureDict["method"] = M.name
                FigureDict["method_desc"] = M.longname
                M.pfile = CWMapFile
                M.ffile = FWMapFile
                M.lfile = LWMapFile
                H, xedges, yedges, extent = M.normalized_data(mode='smoothed',time=1.0/self.config["Smooth.Frequency"])
                print("Plotting {method_desc} for {tel} during '{set}'".format(**FigureDict))
                # Contour map of method
                x,y = M.com()
                P, = cfig.axes[0].plot(x,y,'o-',markersize=14,mew=3)
                M.color = P.get_color()
                x,y = M.max()
                P, = cfig.axes[0].plot(x,y,'^-',color=M.color,mfc=M.color,markersize=14,mew=3)
                LvL = np.max(H) * np.array([0.60,0.80,0.90])
                C = cfig.axes[0].contour(H,LvL,extent=extent,colors=M.color,origin='lower')
                C.collections[0].set_label(M.name)
                # Timeseries of method
                if M.istimeseries():                        
                    Hr, xer, yer, er = M.normalized_data(mode='raw')
                    X,Y,T = M.data(mode='raw',clip=slice(1e3,4e3))
                    Xs,Ys,Ts = M.data(mode='smoothed',time=1.0/self.config["Smooth.Frequency"],clip=slice(1e3,4e3))
                    Mag = np.sqrt(np.power(X,2)+np.power(Y,2))
                    Mags = np.sqrt(np.power(Xs,2)+np.power(Ys,2))
                    if M.lfile and M.luke_data():
                        Xl, Yl = M.luke_data(clip=slice(1e3,4e3))
                        Magl = np.sqrt(np.power(Xl,2)+np.power(Yl,2))
                        M.figures["timeseries"].axes[0].plot(T,Magl,'kx',alpha=0.5)
                        M.figures["timeseries"].axes[1].plot(T,Xl,'kx',alpha=0.5)
                        M.figures["timeseries"].axes[2].plot(T,Yl,'kx',alpha=0.5)
                        
                    M.tst.set_text("Wind Timeseries for {tel_tex} using {method_desc} during {set_tex}".format(**FigureDict))
                    M.figures["timeseries"].axes[0].set_title("Wind Magnitude")
                    M.figures["timeseries"].axes[0].plot(T,Mag,'.',alpha=0.1,mec=M.color,mfc=M.color)
                    M.figures["timeseries"].axes[0].plot(Ts,Mags,'-',color=M.color,lw=2.0)
                    M.figures["timeseries"].axes[0].set_ylabel("Wind Velocity (m/s)")
                    M.figures["timeseries"].axes[0].set_ylim(0,40)
                    M.figures["timeseries"].axes[1].set_title("Wind $x$ velocity")
                    M.figures["timeseries"].axes[1].plot(T,X,'.',alpha=0.5,mec=M.color,mfc=M.color)
                    M.figures["timeseries"].axes[1].plot(Ts,Xs,'-',color=M.color,lw=2.0)
                    M.figures["timeseries"].axes[1].set_ylabel("Wind Velocity (m/s)")
                    M.figures["timeseries"].axes[1].set_ylim(self.limits)
                    M.figures["timeseries"].axes[2].set_title("Wind $y$ velocity")
                    M.figures["timeseries"].axes[2].plot(T,Y,'.',alpha=0.5,mec=M.color,mfc=M.color)
                    M.figures["timeseries"].axes[2].plot(Ts,Ys,'-',color=M.color,lw=2.0)
                    M.figures["timeseries"].axes[2].set_ylabel("Wind Velocity (m/s)")
                    M.figures["timeseries"].axes[2].set_xlabel("Time (s)")
                    M.figures["timeseries"].axes[2].set_ylim(self.limits)
                    M.figures["timeseries"].savefig(FigureName.format(type='timeseries',**FigureDict),
                        dpi=self.config["Figures.DPI"])
                    [ M.figures["timeseries"].axes[i].clear() for i in range(3) ]
                    print("Wrote '{}'".format(FigureName.format(type='timeseries',**FigureDict)))
                    print(u"Post-smoothing residuals: {:.3f} ± {:.3f}".format(np.mean(H-Hr),np.std(H-Hr)))
                    M.figures["bintest"].axes[0].set_title("Wind Map for {tel_tex} using {method_desc} during {set_tex}".format(**FigureDict))
                    M.figures["bintest"].axes[0].imshow(H-Hr,cmap='binary',origin='lower',extent=extent,interpolation='nearest')
                    M.figures["bintest"].axes[0].contour(H,origin='lower',extent=extent)
                    M.figures["bintest"].axes[0].set_xlabel("Velocity (m/s)")
                    M.figures["bintest"].axes[0].set_ylabel("Velocity (m/s)")
                    M.figures["bintest"].savefig(FigureName.format(type='smoothing',**FigureDict))
                    M.figures["bintest"].axes[0].clear()
                    print("Wrote '{}'".format(FigureName.format(type='smoothing',**FigureDict)))

                # Image map of method
                M.figures["map"].axes[0].imshow(H,extent=extent,interpolation='nearest',origin='lower',cmap='binary')
                M.figures["map"].axes[0].contour(H,origin='lower',extent=extent)
                x,y = M.com()
                M.figures["map"].axes[0].plot(x,y,'o-',label="Center: "+M.name,color=M.color,mfc=M.color,markersize=14)
                x,y = M.max()
                M.figures["map"].axes[0].plot(x,y,'^-',label="Max: "+M.name,color=M.color,mfc=M.color,mew=3,markersize=14)
                M.figures["map"].axes[0].set_xlim(self.limits)
                M.figures["map"].axes[0].set_ylim(self.limits)
                M.figures["map"].axes[0].set_xlabel("Velocity (m/s)")
                M.figures["map"].axes[0].set_ylabel("Velocity (m/s)")
                M.figures["map"].axes[0].set_title("Wind Map for {tel_tex} using {method_desc} during {set_tex}".format(**FigureDict))
                M.figures["map"].savefig(FigureName.format(type='histogram',**FigureDict),dpi=self.config["Figures.DPI"])
                M.figures["map"].axes[0].clear()
                print("Wrote '{}'".format(FigureName.format(type='histogram',**FigureDict)))
            cfig.axes[0].set_xlim(self.limits)
            cfig.axes[0].set_ylim(self.limits)
            cfig.axes[0].set_xlabel("Velocity (m/s)")
            cfig.axes[0].set_ylabel("Velocity (m/s)")
            cfig.axes[0].set_title("Wind Map for {tel_tex} during {set_tex}".format(**FigureDict))
            cfig.axes[0].legend()
            FigureDict["method"] = 'all'
            cfig.savefig(FigureName.format(type='contours',**FigureDict),dpi=self.config["Figures.DPI"])
            cfig.axes[0].clear()
            print("Wrote '{}'".format(FigureName.format(type='contours',**FigureDict)))
            
            
if __name__ == '__main__':
    PlotLukeWind.script()
    