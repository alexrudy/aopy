# -*- coding: utf-8 -*-
# 
#  timeseries.py
#  aopy
#  
#  Created by Jaberwocky on 2013-07-29.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)


from .mpl import MPLAnalysis

class TimeSeries(MPLAnalysis):
    """A time series object."""
    
    def magnitude(self,data,axis=2):
        """Return the magnitude"""
        np.sqrt(np.sum(data**2.0,axis=2))
    
    @property
    def latex_title(self):
        """docstring for latex_title"""
        return r"{:s} \verb+{:s}+ {:s}".format(self.data.longname,self.data.casename,self.data.instrument.replace("_"," "))
    
    def timeseries(self,ax,coord=0,smooth=dict(window=100,mode='flat'),rasterize=True,**kwargs):
        """Plot a timeseries on the given axis."""
        rv = []
        if smooth:                
            data = self.data.smoothed(**smooth)
        else:
            data = self.data.data
        if coord < 2:
            kwargs.setdefault('label',"xy"[coord])
            for layer in range(self.data.nlayers):
                rv += list(ax.plot(self.data.time,data[:,layer,coord],**kwargs))
        else:
            kwargs.setdefault('label',"magnitude")
            mdata = self.magnitude(data)
            for layer in range(self.data.nlayers):
                rv += list(ax.plot(self.data.time,mdata[:,layer],**kwargs))
        if rasterize and len(data) > 1e3:
            [ patch.set_rasterized(True) for patch in rv ]
        return rv
        
    def map(self,ax,smooth=None,**kwargs):
        """Plot a histogram map"""
        if smooth:
            data = self.data.smoothed(**smooth)
        else:
            data = self.data.data
        xlabel = kwargs.pop("xlabel", r"$v_x\; \mathrm{(m/s)}$")
        ylabel = kwargs.pop("ylabel", r"$v_y\; \mathrm{(m/s)}$")
        kwargs.setdefault("bins", 51)
        size = kwargs.pop("size", False)
        if size:
            kwargs["range"] = [[-size,size],[-size,size]]
        title = kwargs.pop("label",self.latex_title)
        ax.set_title(title)
        if xlabel:
            ax.set_xlabel(xlabel)
        if ylabel:
            ax.set_ylabel(ylabel)
        circles = kwargs.pop("circles",[10,20,30,40])
        rv = []
        counting = []
        for layer in range(self.data.nlayers):
            (counts, xedges, yedges, Image) = ax.hist2d(data[:,layer,0],data[:,layer,1],**kwargs)
            rv.append(Image)
        
        if isinstance(circles,collections.Sequence):
            rv += self._map_circles(ax,dist=circles)
        return rv
        
    def threepanelts(self,fig,smooth=dict(window=100,mode='flat'),**kwargs):
        """Do the basic threepanel plot"""
        if len(fig.axes) != 3:
            axes = [ fig.add_subplot(3,1,i+1) for i in range(3) ]
            title = kwargs.pop("label",self.latex_title)
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
        