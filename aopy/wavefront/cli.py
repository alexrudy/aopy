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
import numpy as np


class PhasePlayer(pyshell.CLIEngine):
    """Play me some phase!"""
    
    defaultcfg = False
    
    def init(self):
        """Initialize!"""
        super(PhasePlayer, self).init()
        self.parser.add_argument('-o',dest="movie",default="blowing_screen.mp4")
        
    def after_configure(self):
        """Add positional arguments to the file."""
        super(PhasePlayer, self).after_configure()
        self.parser.add_argument('file', help="The input FITS file.", metavar="file.fits")
        self.parser.add_argument('--show',action='store_true',help="Show the movie, don't save it.")
        self.parser.add_argument('--idl', help='IDL Scope to use for .sav files', default='')
        self.parser.add_argument('--log', action='store_true', help='Log-scale data')
        self.parser.add_argument('--delay', help="delay movie start by n frames", type=int, default=0)
        self.parser.add_argument('--sigclip', action='store_true', help='use sigma-clipped data (3sig)')
        self.parser.add_argument('-v','--verbose', action='store_true', help='be verbose')
        
    def get_data(self, filename):
        """Get the data from the file"""
        if filename.endswith('.sav') or filename.endswith('.dat'):
            return self.get_idl_data(filename)
        elif filename.endswith('.fits') or filename.endswith('.fit') or filename.endswith('.gz'):
            return self.get_fits_data(filename)
        else:
            self.log.warning("File is assumed to be FITS: '{}'".format(filename))
            return self.get_fits_data(filename)
            
    def get_fits_data(self, filename):
        """Get the data from a FITS file."""
        from astropy.io import fits
        with fits.open(filename) as HDUs:
            return HDUs[0].data
        
    def get_idl_data(self, filename):
        """Read the data from an IDL save file."""
        from scipy.io.idl import readsav
        scope = readsav(filename)
        data = scope[self.opts.idl]
        if isinstance(data, np.ndarray):
            return data
        else:
            self.log.critical("Data is not an ndarray.")
            raise ValueError("Data: {!r}".format(data))
        
        
    def do(self):
        """Run the phase screen."""
        import matplotlib
        matplotlib.use('TkAgg')
        matplotlib.rcParams['text.usetex'] = False
        
        if self.opts.verbose:
            from matplotlib import verbose
            verbose.set_level('debug')
        
        from astropy.utils.console import ProgressBar
        import matplotlib.pyplot as plt
        from matplotlib import animation
        
        self.data = self.get_data(self.opts.file)
        self.ntime = self.data.shape[0]
        
        if self.opts.log:
            self.data -= np.min(self.data) - 1.0
            self.data = np.log10(self.data)
            
        if self.opts.delay > 0:
            self.data = self.data[self.opts.delay:,...]
            
        if self.opts.sigclip:
            sigma = np.std(self.data)
            mean = np.mean(self.data)
            vlim = (mean - 3 * sigma, mean + 3 * sigma)        
        else:
            vlim = (np.min(self.data),np.max(self.data))
        
        fig = plt.figure(figsize=(9,5))
        ax = fig.add_subplot(111)
        self.I = ax.imshow(self.data[0,...],interpolation='nearest',vmin=vlim[0],vmax=vlim[1])
        fig.colorbar(self.I)
        self.title = ax.set_title("Phase at t=%5d/%5d" % (0,self.ntime))
        anim = animation.FuncAnimation(fig, self.animate, frames=self.data.shape[0], interval=1)
        if self.opts.show:
            print("Showing Phase in live window")
            plt.show()
        else:
            print("Writing Movie...")
            with ProgressBar(self.data.shape[0], file=object() if self.opts.verbose else None) as self.pbar:
                anim.save(self.opts.movie, fps=30, writer='ffmpeg')
        
    def animate(self,t):
        """Animate the screen!"""
        frame = self.data[t,...]
        self.I.set_data(frame)
        self.title.set_text("Phase at t=%5d/%5d" % (t,self.ntime))
        if hasattr(self,'pbar'):
            self.pbar.update()
    

if __name__ == '__main__':
    PhasePlayer.script()
