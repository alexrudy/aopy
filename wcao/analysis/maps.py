# -*- coding: utf-8 -*-
# 
#  maps.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-07-27.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

"""
:mod:`wcao.analysis.maps` – Tools for displaying maps
=====================================================

"""

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)


from .mpl import MPLAnalysis

class WindMap(MPLAnalysis):
    """A two-dimensional wind map."""
    
    map_data_types = [
        
    ]
    
    def __init__(self, data):
        super(WindMap, self).__init__(data)
        
    def _map_circles(self, ax, dist=[0.5,1.0], origin=[0,0], color='w', crosshair=True, zorder=0.1, ls='dashed'):
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
        """Formats a map with velocity information.
        
        :param ax: The matplotlib axes object.
        :param data: The map data object.
        :param kwargs: The imshow keyword arguments.
        
        """
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
        """Show the wind map.
        
        :param ax: A :class:`~matplotlib.axes.Axes` instance.
        :return: `ax`.
        """
        self._map_format(ax, self.data.map, extent=self.data.extent, colorbar_label=r"Wind Strength")
        self._map_circles(ax)
        ax.set_title("Wind Map")
        self._header(ax.figure)
        return ax
