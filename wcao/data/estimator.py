# -*- coding: utf-8 -*-
# 
#  data.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-30.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 


from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import abc
import os, os.path

import numpy as np

from astropy.io import fits

import pyshell
from pyshell.config import DottedConfiguration

class WCAOEstimate(object):
    """A reperesentation of any WCAO data"""
    
    LONGNAMES = {
        'GN' : "Gauss Newton",
        'RT' : "Radon Transform",
        '2D' : "2D Binary Search",
        'XY' : "Split 2D Binary Search",
        'FT' : "Time-Domain Fourier Transform",
        '2L' : "2-Layer Gauss Newton",
    }
    
    ARRAYTYPE = {
    'GN' : "NLTS",
    'RT' : "NLTS",
    '2D' : "NLTS",
    'XY' : "NLTS",
    'FT' : "WLLM",
    '2L' : "NLTS",
    }
    
    __metaclass__ = abc.ABCMeta
    
    def __init__(self, case, data=None, datatype=""):
        super(WCAOEstimate, self).__init__()
        if datatype not in self.ARRAYTYPE or datatype not in self.LONGNAMES:
            raise ValueError("Unknown data type {:s}. Options: {!r}".format(name,self.DATATYPE.keys()))
        self.case = case
        self._datatype = datatype
        self._arraytype = self.ARRAYTYPE[self._datatype]
        self._data = data
        self._config = self.case.config
        self._figurename = os.path.join(
            self.config.get("data.figure.directory","figures"),
            self.config.get("data.figure.template","{datatype:s}_{figtype:s}_{instrument:s}_{name:s}.{ext:s}"),
            )
        self._dataname = os.path.join(
            self.config.get("WCAOEstimate.Data.directory",""),
            self.config.get("WCAOEstimate.Data.template","{datatype:s}_{arraytype:s}_{instrument:s}_{name:s}.{ext:s}")
        )
        self._init_data(data)
        self.log = pyshell.getLogger(__name__)
        
    @property
    def config(self):
        """The configuration!"""
        return self._config
        
    @property
    def longname(self):
        """Expose a long name"""
        return self.LONGNAMES[self._datatype]
        
    @property
    def data(self):
        """Get the actual data!"""
        return self._data
        
    @property
    def fitsname(self):
        """The fits-file name for this object"""
        return self._fitsname.format(
            instrument = self.case.instrument,
            name = self.case.casename,
            ext = self.config.get("WCAOEstimate.Data.fits.ext","fits"),
            datatype = self._datatype,
            arraytype = self._arraytype,
        )
        
    @property
    def npyname(self):
        """Numpy file name for this object"""
        return self._fitsname.format(
            instrument = self.case.instrument,
            name = self.case.casename,
            ext = self.config.get("WCAOEstimate.Data.npy.ext","npy"),
            datatype = self._datatype,
            arraytype = self._arraytype,
        )
    
    @property
    def figname(self):
        """Figure name"""
        return self._figurename.format(
            instrument = self.case.instrument,
            name = self.case.casename,
            ext = self.config.get("WCAOEstimate.Data.npy.ext","npy"),
            datatype = self._datatype,
            figtype = "{figtype:s}",
        )
        
    @abc.abstractmethod
    def _init_data(self,data):
        """This method has no idea how to initialize data!"""
        raise NotImplementedError("{!r} has no concept of data!".format(self))
        

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
            raise ValueError("{0:s}-type data should have 3 dimensions: (time,layer,coord). data.ndim={1.ndim:d}".format(self._arraytype,data))
        if data.shape[2] != 2:
            raise ValueError("{0:s}-type data should have shape (time,nlayers,2). data.shape={1.shape!r}".format(self._arraytype,data))
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
        """Load the data from a file."""
        if filename is None:
            filename = self.npyname
        self._init_data(np.load(filename))
            
    def save(self,filename=None):
        """Save the data to a fits file."""
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
        rv = []
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
            self.timeseries(axes[i],coord=i,smooth=smooth,label="Wind {:s}".format(label),marker='None',ls='-',alpha=0.2,**kwargs)
            self.timeseries(axes[i],coord=i,label="Wind {:s}".format(label),marker='.',alpha=0.2,**kwargs)
            axes[i].set_title("Wind {:s}".format(label))
            axes[i].set_ylabel("Speed (m/s)")
        return fig
        
        
        