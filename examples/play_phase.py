#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  play_phase.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-03.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import pyshell

class PhasePlayer(pyshell.CLIEngine):
    """Play me some phase!"""
    
    defaultcfg = False
    
    def init(self):
        """Initialize!"""
        super(PhasePlayer, self).init()
        self.parser.add_argument('-f',dest='fitsfile', help="The input FITS file.", metavar="file.fits")
        self.parser.add_argument('-o',dest="movie",default="blowing_screen.mp4")
        
    def do(self):
        """Run the phase screen."""
        import matplotlib
        import matplotlib.pyplot as plt
        from matplotlib import animation
        import numpy as np
        from astropy.io import fits
        
        self.ffile = fits.open(self.opts.fitsfile)
        self.ntime = self.ffile[0].data.shape[0]
        self.vlim = (np.min(self.ffile[0].data),np.max(self.ffile[0].data))
        
        self.fig = plt.figure()
        self.ax = self.fig.add_subplot(111)
        self.I = self.ax.imshow(self.ffile[0].data[0,...],interpolation='nearest',vmin=self.vlim[0],vmax=self.vlim[1])
        self.fig.colorbar(self.I)
        self.ax.set_title("Phase at t=%5d/%5d" % (0,self.ntime))
        self.anim = animation.FuncAnimation(self.fig, self.animate, frames=self.ntime, interval=20)
        self.anim.save(self.opts.movie, fps=30, extra_args=['-vcodec', 'libx264'],
        writer='ffmpeg_file',)
        # plt.show()
        
    def animate(self,t):
        """Animate the screen!"""
        frame = self.ffile[0].data[t,...]
        self.I.set_data(frame)
        self.ax.set_title("Phase at t=%5d/%5d" % (t,self.ntime))
        
    

if __name__ == '__main__':
    PhasePlayer.script()
