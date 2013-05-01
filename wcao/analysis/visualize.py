# -*- coding: utf-8 -*-
# 
#  visualize.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-04-30.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

import matplotlib.patches
import matplotlib.lines
import matplotlib.collections

def make_circles(Rs,crosshair=True,center=(0,0),color='k'):
    """Make circles for plotting."""
    patches = [ matplotlib.patches.Circle(center,R,fc='none',ec=color,ls='dashed',zorder=0.1) for R in Rs ]
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