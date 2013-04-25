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
import matplotlib.patches
import matplotlib.lines
import matplotlib.collections
import numpy as np
import pyfits as pf
import os.path, glob
import scipy.ndimage
import logging,warnings
import subprocess

from pyshell.util import query_string, is_type_factory, check_exists
from pyshell.base import CLIEngine
import pyshell

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

def make_circles(Rs,crosshair=True,center=(0,0),color='k'):
    """Make circles for plotting."""
    patches = [matplotlib.patches.Circle(center,R,fc='none',ec=color,ls='dashed',zorder=0.1) for R in Rs]
    if crosshair:
        Rmax = max(Rs)
        major = [ -Rmax, Rmax ]
        minor = [ 0 , 0 ]
        coords = [ (major,minor), (minor,major)]
        for xdata,ydata in coords:
            patches.append(
                matplotlib.lines.Line2D(xdata,ydata,ls='dashed',color=color,marker='None',zorder=0.1)
            )
    return patches
    
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
    
    multilayer_names = ['2La','2Lb']
    phase_names = ['GN','RT','2D','XY'] + multilayer_names
    fourier_names = ['FT']
    longnames = {
        'GN' : "Gauss Newton",
        'RT' : "Radon Transform",
        '2D' : "2D Binary Search",
        'XY' : "Split 2D Binary Search",
        'FT' : "Time-Domain Fourier Transform",
        '2La' : "2-Layer Gauss Newton A",
        '2Lb' : "2-Layer Guass Newton B"
    }
    nbins = {
        'GN' : 51,
        'RT' : 51,
        '2D' : 51,
        'XY' : 51,
        'FT' : 161,
        '2La': 51,
        '2Lb': 51,
    }
    fn = os.path.join("figures","{type}_{method}_{tel}_{set}.{ext}")
    log = logging.getLogger(__name__)
    
    
    def __init__(self,name,**kwargs):
        super(_WindPredictionMethod, self).__init__()
        self.__dict__.update(kwargs)
        self.name = name
        if self.name not in self.longnames:
            raise AttributeError("Unkown Method!")
        self.fd = {
            'method': self.name,
            'method_desc' : self.longname,
        }
        self.color = 'k'

    def istimeseries(self):
        """Check if this is a timeseries dataset."""
        return self.name in self.phase_names
        
    def ismultilayer(self):
        """Check if this is a multi-layer timeseries"""
        return self.name in self.multilayer_names
        
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
        
    def patch_coords(self,x,y):
        """Get the coordinates from an index."""
        if np.any(np.isnan([x,y])):
            x, y = [0,0]
            self.log.warning("Coordinates are NaN! Setting to [0,0]")
            return x,y
        if len(self.y)-1 < y+1:
            y = self.y[y]
        else:
            y = (self.y[y] + self.y[y+1])/2.0
        if len(self.x)-1 < x+1:
            x = self.x[x]
        else:
            x = (self.x[x] + self.x[x+1])/2.0
            
        return x,y
        
    def com(self):
        """Return the (x,y) position of the centered data"""
        c,r = scipy.ndimage.measurements.center_of_mass(self.H)
        return self.patch_coords(r,c)
        
    def max(self):
        """Return the (x,y) position of the maximum coordinate"""
        arg = np.argmax(self.H)
        c,r = np.unravel_index(arg,self.H.shape)
        return self.patch_coords(r,c)

class PlotLukeWind(CLIEngine):
    """docstring for PlotLukeWind"""
    defaultcfg = "windplots.yml"
    supercfg = pyshell.PYSHELL_LOGGING_STREAM
    log = logging.getLogger(__name__)
    
    def init(self):
        """docstring for init"""
        super(PlotLukeWind, self).init()
        self.parser.add_argument('-o','--open',help="Open the created images using OSX's open command.",action="store_true")
    
    def configure(self):
        """Initialize un-configured arguments"""
        super(PlotLukeWind, self).configure()
        self.parser.add_argument("name",help="File name or index",action='store',nargs="*")
        self.log.setLevel(logging.DEBUG)
        self.methods = {}
        for meth in self.config.get("Methods.Base",[]):
            self.methods[meth] = _WindPredictionMethod(name=meth)
        self.limits = (self.config["Maps.Limits.min"],self.config["Maps.Limits.max"])
        self.circles = np.linspace(0,max(self.limits),5,endpoint=True)[1:]
        
    def _setup_methods(self):
        """docstring for _setup_methods"""
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
        
    def _add_to_cmap(self,M):
        """Add to full contour map"""
        # Contour map of method
        H, xedges, yedges, extent = M.normalized_data(mode='smoothed',time=1.0/self.config["Smooth.Frequency"])
        x,y = M.com()
        if np.sum(np.isnan([x,y])):
            x, y = [0,0]
        PA, = self.cfig.axes[0].plot(x,y,'o-',markersize=14,mew=3)
        M.color = PA.get_color()
        x,y = M.max()
        PB, = self.cfig.axes[0].plot(x,y,'^-',color=M.color,mfc=M.color,markersize=14,mew=3)
        C = self.cfig.axes[0].contour(H,10,extent=extent,colors=M.color,origin='lower')
        [ c.remove() for c  in C.collections[:5] ]
        C.collections[-1].set_label(M.name)
        
        
    def _save_cmap(self,filename,fd):
        """docstring for _save_cmap"""
        self.cfig.axes[0].set_xlim(self.limits)
        self.cfig.axes[0].set_ylim(self.limits)
        [ self.cfig.axes[0].add_artist(a) for a in make_circles(self.circles,color=self.config.get("Maps.Grid.color","k")) ]
        self.cfig.axes[0].add_artist(matplotlib.patches.Circle((0,0),self.config.get("Maps.Limits.rmin"),fc='none',ec='k',alpha=0.5,zorder=0.1))
        self.cfig.axes[0].set_xlabel("Velocity (m/s)")
        self.cfig.axes[0].set_ylabel("Velocity (m/s)")
        self.cfig.axes[0].set_title("Wind Map for {tel_tex} during {set_tex}".format(**fd))
        self.cfig.axes[0].legend()
        self.cfig.savefig(filename,dpi=self.config["Figures.DPI"])
        self.cfig.axes[0].clear()
        self.log.debug("Wrote '{}'".format(filename))
        return filename
        
    def _make_timesiers(self,M,filename,clear=False):
        """docstring for _make_"""
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
        
        M.tst.set_text("Wind Timeseries for {tel_tex} using {method_desc} during {set_tex}".format(**M.fd))
        M.figures["timeseries"].axes[0].set_title("Wind Magnitude")
        M.figures["timeseries"].axes[0].plot(T,Mag,'.',alpha=0.1,mec=M.color,mfc=M.color)
        M.figures["timeseries"].axes[0].plot(Ts,Mags,'-',color=M.color,lw=2.0,alpha=0.1)
        M.figures["timeseries"].axes[0].set_ylabel("Wind Velocity (m/s)")
        M.figures["timeseries"].axes[0].set_ylim(0,np.max(self.limits))
        M.figures["timeseries"].axes[1].set_title("Wind $x$ velocity")
        M.figures["timeseries"].axes[1].plot(T,X,'.',alpha=0.5,mec=M.color,mfc=M.color)
        M.figures["timeseries"].axes[1].plot(Ts,Xs,'-',color=M.color,lw=2.0,alpha=0.1)
        M.figures["timeseries"].axes[1].set_ylabel("Wind Velocity (m/s)")
        M.figures["timeseries"].axes[1].set_ylim(self.limits)
        M.figures["timeseries"].axes[2].set_title("Wind $y$ velocity")
        M.figures["timeseries"].axes[2].plot(T,Y,'.',alpha=0.5,mec=M.color,mfc=M.color)
        M.figures["timeseries"].axes[2].plot(Ts,Ys,'-',color=M.color,lw=2.0,alpha=0.1)
        M.figures["timeseries"].axes[2].set_ylabel("Wind Velocity (m/s)")
        M.figures["timeseries"].axes[2].set_xlabel("Time (s)")
        M.figures["timeseries"].axes[2].set_ylim(self.limits)
        self.log.debug("Plotted {method_desc} in {color:s}".format(color=M.color,**M.fd))
        M.figures["timeseries"].savefig(filename,dpi=self.config["Figures.DPI"])
        if clear:
            [ M.figures["timeseries"].axes[i].clear() for i in range(3) ]
        self.log.debug("Wrote '{}'".format(filename))
        return filename
        
    def _make_bintest(self,M,filename):
        """docstring for _make_bintest"""
        H, xedges, yedges, extent = M.normalized_data(mode='smoothed',time=1.0/self.config["Smooth.Frequency"])
        Hr, xer, yer, er = M.normalized_data(mode='raw')
        M.figures["bintest"].axes[0].set_title("Wind Map for {tel_tex} using {method_desc} during {set_tex}".format(**M.fd))
        M.figures["bintest"].axes[0].imshow(H-Hr,cmap=self.config.get("Maps.cmap",None),origin='lower',extent=extent,interpolation='nearest')
        M.figures["bintest"].axes[0].contour(H,origin='lower',extent=extent)
        M.figures["bintest"].axes[0].set_xlabel("Velocity (m/s)")
        M.figures["bintest"].axes[0].set_ylabel("Velocity (m/s)")
        [ M.figures["bintest"].axes[0].add_artist(a) for a in make_circles(self.circles,color=self.config.get("Maps.Grid.imcolor","k")) ]
        M.figures["bintest"].savefig(filename)
        M.figures["bintest"].axes[0].clear()
        self.log.debug("Wrote '{}'".format(filename))
        return filename
        
    def _sub_map(self,M,ax):
        """docstring for _sub_map"""
        H, xedges, yedges, extent = M.normalized_data(mode='smoothed',time=1.0/self.config["Smooth.Frequency"])
        if M.istimeseries():
            ax.imshow(H,extent=extent,interpolation='nearest',origin='lower',cmap=self.config.get("Maps.cmap",None))
        else:
            ax.imshow(H,extent=extent,interpolation='nearest',origin='lower',cmap=self.config.get("Maps.cmap",None),vmin=0,vmax=1)
        C = ax.contour(H,10,origin='lower',extent=extent)
        [ c.remove() for c  in C.collections[:5] ]
        x,y = M.com()
        # PA, = ax.plot(x,y,'o-',label="Center: "+M.name,color=M.color,mfc=M.color,markersize=14,mew=3)
        x,y = M.max()
        # PB, = ax.plot(x,y,'^-',label="Max: "+M.name,color=M.color,mfc=M.color,mew=3,markersize=14)
        [ ax.add_artist(a) for a in make_circles(self.circles,color=self.config.get("Maps.Grid.imcolor","k")) ]
        ax.add_artist(matplotlib.patches.Circle((0,0),self.config.get("Maps.Limits.rmin"),fc='none',ec='k',alpha=0.5,zorder=0.1))
        ax.set_xlim(self.limits)
        ax.set_ylim(self.limits)
        ax.set_xlabel("Velocity (m/s)")
        ax.set_ylabel("Velocity (m/s)")
        ax.set_title("{method_desc}".format(**M.fd))
        
    def _make_map(self,M,filename):
        """docstring for _make_map"""
        H, xedges, yedges, extent = M.normalized_data(mode='smoothed',time=1.0/self.config["Smooth.Frequency"])
        M.figures["map"].axes[0].imshow(H,extent=extent,interpolation='nearest',origin='lower',cmap=self.config.get("Maps.cmap",None))
        C = M.figures["map"].axes[0].contour(H,10,origin='lower',extent=extent)
        [ c.remove() for c  in C.collections[:5] ]
        x,y = M.com()
        # PA, = M.figures["map"].axes[0].plot(x,y,'o-',label="Center: "+M.name,color=M.color,mfc=M.color,markersize=14,mew=3)
        x,y = M.max()
        # PB, = M.figures["map"].axes[0].plot(x,y,'^-',label="Max: "+M.name,color=M.color,mfc=M.color,mew=3,markersize=14)
        [ M.figures["map"].axes[0].add_artist(a) for a in make_circles(self.circles,color=self.config.get("Maps.Grid.imcolor","k")) ]
        M.figures["map"].axes[0].add_artist(matplotlib.patches.Circle((0,0),self.config.get("Maps.Limits.rmin"),fc='none',ec='k',alpha=0.5,zorder=0.1))
        M.figures["map"].axes[0].set_xlim(self.limits)
        M.figures["map"].axes[0].set_ylim(self.limits)
        M.figures["map"].axes[0].set_xlabel("Velocity (m/s)")
        M.figures["map"].axes[0].set_ylabel("Velocity (m/s)")
        M.figures["map"].axes[0].set_title("Wind Map for {tel_tex} using {method_desc} during {set_tex}".format(**M.fd))
        M.figures["map"].savefig(filename,dpi=self.config["Figures.DPI"])
        M.figures["map"].axes[0].clear()
        self.log.debug("Wrote '{}'".format(filename))
        return filename
        
    def do(self):
        """Take action!"""
        files = glob.glob("data/{inst}/proc/*_phase.fits".format(inst=self.config.get("instrument","**")))
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
                self.log("Skipping File '{}'".format(fname))
        
        self.log.info("Examining:")
        for filename in FileNames:
            self.log.info(" - '{:s}' ".format(filename))
        self.log.info("Plotting {!r} {!r}".format(self.config["Plots.Enable"],isinstance(self.config["Plots.Enable"],list)))
        self._setup_methods()
        
        for FileName in FileNames:
            BaseName   = os.path.splitext(os.path.basename(FileName))[0]
            Instrument = FileName.split("/")[1]
            FigureDict  = {
                'tel' : Instrument,
                'tel_tex' : Instrument.replace("_"," "),
                'set' : BaseName,
                'set_tex' : r"\verb+{}+".format(BaseName),
                'ext' : "png"
            }
            Figures = set()
            CWMapFile = pf.open(FileName+'_wind.fits')
            FWMapFile = pf.open(FileName+'_fwmap.fits')
            if check_exists(FileName+'_luke_wind.fits'):
                LWMapFile = pf.open(FileName+'_luke_wind.fits')
            else:
                LWMapFile = False
            self.log.info("Examining '{set}' for {tel}".format(**FigureDict))
            self.cfig = plt.figure(dpi=self.config["Figures.DPI"])
            self.cfig.add_subplot(1,1,1)
            self.mmfig = plt.figure(dpi=self.config["Figures.DPI"])
            [ self.mmfig.add_subplot(2,2,i+1) for i in range(4) ]
            for method in self.config.get("Methods.Enable",[]):
                M = self.methods[method]
                M.fd.update(FigureDict)
                M.pfile = CWMapFile
                M.ffile = FWMapFile
                M.lfile = LWMapFile
                self.log.info("Plotting {method_desc} for {tel} during '{set}'".format(**M.fd))
                if "cmap" in self.config.get("Plots.Enable",[]):
                    self._add_to_cmap(M)
                # Timeseries of method
                if M.istimeseries() and M.ismultilayer():
                    if "timeseries" in self.config.get("Plots.Enable",[]):
                        clear = M.name != '2La'
                        Figures.add(self._make_timesiers(M,M.fn.format(type='timeseries',**M.fd),clear))
                    if "bintest" in self.config.get("Plots.Enable",[]):
                        Figures.add(self._make_bintest(M,M.fn.format(type='smoothing',**M.fd)))
                elif M.istimeseries():
                    if "timeseries" in self.config.get("Plots.Enable",[]):
                        Figures.add(self._make_timesiers(M,M.fn.format(type='timeseries',**M.fd)))
                    if "bintest" in self.config.get("Plots.Enable",[]):
                        Figures.add(self._make_bintest(M,M.fn.format(type='smoothing',**M.fd)))
                # Image map of method
                if "map" in self.config.get("Plots.Enable",[]):
                    Figures.add(self._make_map(M,M.fn.format(type='histogram',**M.fd)))
                if "mmap" in self.config.get("Plots.Enable",[]) and M.name in self.config["Methods.MMap"]:
                    self._sub_map(M,self.mmfig.axes[self.config["Methods.MMap"].index(M.name)])
            if "cmap" in self.config.get("Plots.Enable",[]):
                Figures.add(self._save_cmap(_WindPredictionMethod.fn.format(type='contours',method='all',**FigureDict),FigureDict))
            if "mmap" in self.config.get("Plots.Enable",[]):
                self.mmfig.suptitle("Wind Map for {tel_tex} during {set_tex}".format(**FigureDict))
                self.mmfig.savefig(_WindPredictionMethod.fn.format(type='mmap',method='all',**FigureDict))
                Figures.add(_WindPredictionMethod.fn.format(type='mmap',method='all',**FigureDict))
            if self.opts.open:
                subprocess.Popen(["open"] + list(Figures))
                
            
if __name__ == '__main__':
    PlotLukeWind.script()
    