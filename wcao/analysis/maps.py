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
