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
            raise ValueError("{0:s}-type data should have shape (1(time),nlayers,2(x/y)). data.shape={1.shape!r}".format(self._arraytype,data))
        self._data = data
        
        
    @property
    def data(self):
        """docstring for data"""
        if isinstance(self.clip,slice):
            return self._data[self.clip,...]
        else:
            return self._data
        
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
                rv[:,layer,i] = smooth(self.data[:,layer,i],window,mode)
        return rv
    
    def timeseries(self,ax,coord=0,smooth=dict(window=100,mode='flat'),**kwargs):
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
        if len(data) > 1e3:
            [ patch.set_rasterized(True) for patch in rv ]
        return rv
        
    def map(self,ax,smooth=None,**kwargs):
        """Plot a histogram map"""
        if smooth:
            data = self.smoothed(**smooth)
        else:
            data = self.data
        kwargs.setdefault("bins",51)
        size = kwargs.pop("size",False)
        if size:
            kwargs["range"] = [[-size,size],[-size,size]]
        title = kwargs.pop("label",r"{:s} \verb+{:s}+ {:s}".format(self.longname,self.case.casename,self.case.instrument))
        ax.set_title(title)
        circles = kwargs.pop("circles",[10,20,30,40])
        rv = []
        if isinstance(circles,collections.Sequence):
            circle_patch = make_circles(circles,color='w')
            [ ax.add_artist(a) for a in circle_patch ]
            rv += circle_patch
        
        for layer in range(self.nlayers):
            (counts, xedges, yedges, Image) = ax.hist2d(data[:,layer,0],data[:,layer,1],**kwargs)
            rv.append(Image)
        return rv
        
    def threepanelts(self,fig,smooth=dict(window=100,mode='flat'),**kwargs):
        """Do the basic threepanel plot"""
        if len(fig.axes) != 3:
            axes = [ fig.add_subplot(3,1,i+1) for i in range(3) ]
            title = kwargs.pop("label",r"{:s} \verb+{:s}+ {:s}".format(self.longname,self.case.casename,self.case.instrument))
            fig.suptitle(title)
        else:
            axes = fig.axes
        labels = ["$w_x$","$w_y$","$|w|$"]
        for i in range(3):
            label = labels[i]
            self.timeseries(axes[i],coord=i,label="Wind {:s}".format(label),marker='.',alpha=0.2,**kwargs)
            self.timeseries(axes[i],coord=i,smooth=smooth,label="Wind {:s}".format(label),marker='None',ls='-',alpha=1.0,**kwargs)
            axes[i].set_title("Wind {:s}".format(label))
            axes[i].set_ylabel("Speed (m/s)")
        return fig
