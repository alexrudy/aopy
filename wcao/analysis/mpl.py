# -*- coding: utf-8 -*-
# 
#  mpl.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-07-27.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 


from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import datetime

from ..data import WCAOData

class MPLAnalysis(object):
    """A matplotlib analysis object"""
    def __init__(self, data):
        super(MPLAnalysis, self).__init__()
        if not isinstance(data, WCAOData)
            raise ValueError("{} requires an instance of {}, got {}".format(
                self, WCAOData.__name__, type(data)
            ))
        self.data = data
        
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
        
    def _header(self,fig):
        """Add an object's header values."""
        from matplotlib.figure import Figure
        if not isinstance(fig, Figure):
            raise TypeError("{}._header requires an instance of {}, got {}".format(
                self, Figure, type(fig)
            ))
        if getattr(fig,'_has_wcao_header',False):
            return
        else:
            fig._has_wcao_header = True
        
        inst = self.data.case.instrument.replace("_"," ")
        casename = self.data.case.casename
        ltext = r"{instrument:s} during \verb|{casename:s}|".format(instrument=inst,casename=casename)
        fig.text(0.02,0.98,ltext,ha='left',va='top')
        
        today = datetime.date.today().isoformat()
        rtext = r"Analysis on {date:s} with {config:s}".format(date=today,config=self.data.case.config.hash)
        fig.text(0.98,0.98,rtext,ha='right',va='top')