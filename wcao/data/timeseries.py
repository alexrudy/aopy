# -*- coding: utf-8 -*-
# 
#  timeseries.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-01.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np

import collections

from .estimator import WCAOEstimate


class WCAOTimeseries(WCAOEstimate):
    """A representation of WCAO timeseries data"""
    def __init__(self,*args,**kwargs):
        self._timestep = kwargs.pop('timestep',1.0)
        super(WCAOTimeseries, self).__init__(*args, **kwargs)
        self.clip = False
        
    def _init_data(self,data):
        """Initialize and validate timeseires data"""
        if data is None:
            return
        data = np.array(data)
        if data.ndim != 3:
            raise ValueError("{0:s}-type data should have 3 dimensions: (time,layer,x/y). data.ndim={1.ndim:d}".format(self._arraytype,data))
        if data.shape[2] != 2:
            raise ValueError("{0:s}-type data should have shape (ntime,nlayers,2(x/y)). data.shape={1.shape!r}".format(self._arraytype,data))
        self._data = data
        
    
    def apply_clip(self,data):
        """docstring for apply_clip"""
        if isinstance(self.clip,slice):
            return data[self.clip,...]
        else:
            return data
    
    @property
    def data(self):
        """docstring for data"""
        return self.apply_clip(self._data)
        
    @property
    def nlayers(self):
        """Number of layers in this data"""
        return self.data.shape[1]
        
    @property
    def ntime(self):
        """Number of timesteps"""
        return self.data.shape[0]
        
    @property
    def time(self):
        """The time array"""
        return np.arange(self.ntime) * self._timestep
        
    def load(self,filename=None):
        """Load the data from a numpy file."""
        if filename is None:
            filename = self.npyname
        self._init_data(np.load(filename))
        
    def load_IDL(self,filename,method_index=0):
        """Load the IDL format of this data."""
        from astropy.io import fits
        
        with fits.open(filename) as HDUs:
            data = HDUs[0].data.copy()[:,:2,method_index]
            data = data[:,np.newaxis,:]
        self._init_data(data)
            
            
    def save(self,filename=None):
        """Save the data to a numpy file."""
        if filename is None:
            filename = self.npyname
        np.save(filename,self._data)
            
            
    def smoothed(self,window,mode='flat'):
        """docstring for smoothed"""
        from aopy.util.math import smooth
        rv = np.zeros_like(self.data)
        for layer in range(self.nlayers):
            for i in [0,1]:
                rv[:,layer,i] = self.apply_clip(smooth(self._data[:,layer,i],window,mode))
        return rv
    
    def timeseries(self,ax,coord=0,smooth=dict(window=100,mode='flat'),rasterize=True,**kwargs):
        """Plot a timeseries on the given axis."""
        rv = []
        if smooth:                
            data = self.smoothed(**smooth)
        else:
            data = self.data
        if coord < 2:
            kwargs.setdefault('label',"xy"[coord])
            for layer in range(self.nlayers):
                rv += list(ax.plot(self.time,data[:,layer,coord],**kwargs))
        else:
            kwargs.setdefault('label',"magnitude")
            mdata = np.sqrt(np.sum(data**2.0,axis=2))
            for layer in range(self.nlayers):
                rv += list(ax.plot(self.time,mdata[:,layer],**kwargs))
        if rasterize and len(data) > 1e3:
            [ patch.set_rasterized(True) for patch in rv ]
        return rv
        
    def map(self,ax,smooth=None,**kwargs):
        """Plot a histogram map"""
        if smooth:
            data = self.smoothed(**smooth)
        else:
            data = self.data
        xlabel = kwargs.pop("xlabel",r"$v_x\; \mathrm{(m/s)}$")
        ylabel = kwargs.pop("ylabel",r"$v_y\; \mathrm{(m/s)}$")
        kwargs.setdefault("bins",51)
        size = kwargs.pop("size",False)
        if size:
            kwargs["range"] = [[-size,size],[-size,size]]
        title = kwargs.pop("label",r"{:s} \verb+{:s}+ {:s}".format(self.longname,self.case.casename,self.case.instrument.replace("_"," ")))
        ax.set_title(title)
        if xlabel:
            ax.set_xlabel(xlabel)
        if ylabel:
            ax.set_ylabel(ylabel)
        circles = kwargs.pop("circles",[10,20,30,40])
        rv = []
        counting = []
        for layer in range(self.nlayers):
            (counts, xedges, yedges, Image) = ax.hist2d(data[:,layer,0],data[:,layer,1],**kwargs)
            rv.append(Image)
        
        if isinstance(circles,collections.Sequence):
            rv += self._circles(ax,dist=circles)
        return rv
        
    def threepanelts(self,fig,smooth=dict(window=100,mode='flat'),**kwargs):
        """Do the basic threepanel plot"""
        if len(fig.axes) != 3:
            axes = [ fig.add_subplot(3,1,i+1) for i in range(3) ]
            title = kwargs.pop("label",r"{:s} \verb+{:s}+ {:s}".format(self.longname,self.case.casename,self.case.instrument.replace("_"," ")))
            fig.suptitle(title)
        else:
            axes = fig.axes
        labels = ["$w_x$","$w_y$","$|w|$"]
        for i in range(3):
            label = labels[i]
            self.timeseries(axes[i],coord=i,smooth=False,label="Wind {:s}".format(label),marker='.',alpha=0.1,ls='None',**kwargs)
            self.timeseries(axes[i],coord=i,smooth=smooth,label="Wind {:s}".format(label),marker='None',ls='-',alpha=1.0,lw=2.0,**kwargs)
            axes[i].set_title("Wind {:s}".format(label))
            axes[i].set_ylabel("Speed (m/s)")
            
        lims = []
        for i in range(2):
            lims += list(axes[i].get_ylim())
        
        for i in range(3):
            if i == 2:
                ym,yp = axes[i].get_ylim()
                axes[i].set_ylim(0.0,yp)
                axes[i].set_xlabel("Time (s)")
            else:
                axes[i].set_ylim(min(lims),max(lims))
        
        return fig
        
    def _circles(self,ax,dist=10,origin=[0,0],color='w',crosshair=True):
        """Show circles"""
        from matplotlib.patches import Circle
        from matplotlib.lines import Line2D
        circles = [Circle(origin,R,fc='none',ec=color,ls='dashed',zorder=0.1) for R in dist]
        if crosshair:
            Rmax = max(dist)
            major = [ -Rmax, Rmax ]
            minor = [ 0 , 0 ]
            coords = [ (major,minor), (minor,major)]
            for xdata,ydata in coords:
                circles.append(
                    Line2D(xdata,ydata,ls='dashed',color=color,marker='None',zorder=0.1)
                )
        [ ax.add_artist(a) for a in circles ]
        return circles
