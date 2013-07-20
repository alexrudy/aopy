# -*- coding: utf-8 -*-
# 
#  windmap.py
#  aopy
#  
#  Created by Jaberwocky on 2013-07-15.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
"""
:mod:`wcao.data.windmap` - A generic windmap class for WCAO results.
====================================================================


"""

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)
import numpy as np

import datetime
import os.path

from .estimator import WCAOEstimate, set_wcao_header_values, verify_wcao_header_values

def set_v_metric_headers(hdu,vx,vy):
    """Set the appropriate header values for wind-velocity metric arrays."""
    hdu.header["WCAOmaxv"] = (np.max(vx), "Maximum searched x velocity")
    hdu.header["WCAOmixv"] = (np.min(vx), "Minimum searched x velocity")
    hdu.header["WCAOnuxv"] = (len(vx), "Number of x velocity gridpoints")
    hdu.header["WCAOmayv"] = (np.max(vy), "Maximum searched y velocity")
    hdu.header["WCAOmiyv"] = (np.min(vy), "Minimum searched y velocity")
    hdu.header["WCAOnuyv"] = (len(vy), "Number of y velocity gridpoints")
    hdu.header["WCAOrecv"] = ("np.linspace(WCAOMI?V,WCAOMA?V,WCAONU?V)","Psuedocode to reconstruct velocity grids.")
    return hdu
    
    
def read_v_metric_headers(hdu):
    """Read the appropriate header values for wind-velocity metric arrays."""
    vx = np.linspace(float(hdu.header["WCAOmixv"]),float(hdu.header["WCAOmaxv"]),int(hdu.header["WCAOnuxv"]))
    vy = np.linspace(float(hdu.header["WCAOmiyv"]),float(hdu.header["WCAOmayv"]),int(hdu.header["WCAOnuyv"]))
    return vx,vy
    
    
def save_map(wmap,vx,vy,wcaotype):
    """Saves the minimum amount of information to reconstruct a given map."""
    from astropy.io import fits
    hdu = fits.ImageHDU(wmap)
    set_wcao_header_values(hdu,wcaotype)
    set_v_metric_headers(hdu,vx,vy)
    return hdu

def load_map(hdu,wcaotype=None,scale=True):
    """Load a map from an HDU"""
    verify_wcao_header_values(hdu,wcaotype)
    wmap = hdu.data.copy()
    if scale:
        vx,vy = read_v_metric_headers(hdu)
        return wmap,vx,vy
    else:
        return wmap


class WCAOMap(WCAOEstimate):
    """A generic WCAO estimate as a map."""
    
    def _init_data(self,data):
        """Data initialization."""
        if isinstance(data, np.ndarray):
            if data.ndim == 2:
                self.map = data
        elif isinstance(data, tuple):
            if len(data) == 3:
                self.map, self.vx, self.vy = data
                
    @property
    def extent(self):
        """The extent array for this map."""
        return [np.min(self.vx),np.max(self.vx),np.min(self.vy),np.max(self.vy)]
        
    def _map_circles(self, ax, dist=10, origin=[0,0], color='w', crosshair=True, zorder=0.1, ls='dashed'):
        """Show map circles in a crosshair pattern."""
        from matplotlib.patches import Circle
        from matplotlib.lines import Line2D
        xm,xp = ax.get_xlim()
        ym,yp = ax.get_ylim()
        rm = np.max(np.abs([xm, xp, ym, yp]))
        nc = rm//dist
        Rs = [ (n+1)*dist for n in range(int(nc)) ]
        circles = [ Circle(origin, R, fc='none', ec=color, ls=ls, zorder=zorder) for R in Rs]
        if crosshair:
            Rmax = max(Rs)
            major = [ -Rmax, Rmax ]
            minor = [ 0 , 0 ]
            coords = [ (major, minor), (minor, major)]
            for xdata,ydata in coords:
                circles.append(
                    Line2D(xdata,ydata, ls=ls, color=color, marker='None', zorder=zorder)
                )
        [ ax.add_artist(a) for a in circles ]
        return circles
        
    def _map_format(self,ax,data,**kwargs):
        """Formats a map with velocity information."""
        kwargs.setdefault('extent',self.extent)
        kwargs.setdefault('interpolation','nearest')
        kwargs.setdefault('origin','lower')
        
        xlabel = kwargs.pop('xlabel',r"$v_x\; \mathrm{(m/s)}$")
        ylabel = kwargs.pop('ylabel',r"$v_y\; \mathrm{(m/s)}$")
        
        colorbar = kwargs.pop('colorbar',True)
        colorbar_kw = kwargs.pop('colorbar_kw',{})
        colorbar_label = kwargs.pop('colorbar_label',False)
        
        image = ax.imshow(data,**kwargs)
        if colorbar:
            cbar = ax.figure.colorbar(image,**colorbar_kw)
            if colorbar_label:
                cbar.set_label(colorbar_label)
        else:
            cbar = None
        
        if xlabel:
            ax.set_xlabel(xlabel)
        if ylabel:
            ax.set_ylabel(ylabel)
        
        return cbar
        
    def show_map(self,ax):
        """Show this wind map."""
        self._map_format(ax, self.map, colorbar_label=r"Wind Strength")
        self._map_circles(ax)
        ax.set_title("Wind Map")
        self._header(ax.figure)
        