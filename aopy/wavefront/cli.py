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
from pyshell.util import is_type, ipydb
import numpy as np
import six
import sys
import os, os.path

class PhaseMovieView(object):
    """A view for a phase movie"""
    def __init__(self, ax, cube, norm=None, cmap='jet', title='Phase at {0: 5.0f}/{1:05.0f}', cb_show=True, cb_label='phase error', time=None, **kwargs):
        super(PhaseMovieView, self).__init__()
        from matplotlib.colors import Normalize
        
        self.ax = ax
        self.cube = cube
        
        if norm is None:
            norm = Normalize()
        self.norm = norm
        
        self.cmap = cmap
        self.cb_label = cb_label
        self.cb_show = cb_show
        self.title = title
        
        if time is None:
            time = np.arange(self.cube.shape[0], dtype=np.float)
        self.time = time
        self._index = 0
        self.paused = False
        
        
        self._image_kwargs = kwargs
        self._setup = False
        self._connections = {}
        
    def symlognorm(self, n_sigma=3):
        """docstring for symlognorm"""
        from matplotlib.colors import SymLogNorm
        nonzero = np.abs(self.cube[self.cube != 0.0])
        limit = np.mean(nonzero) - n_sigma * np.std(nonzero)
        self.norm = SymLogNorm(limit, linscale=0.01)
        
    def setup(self):
        """Setup the axes."""
        self._image = self.ax.imshow(self.cube[0,...],interpolation='nearest', cmap=self.cmap, norm=self.norm, **self._image_kwargs)
        self._title = self.ax.set_title(self.title.format(self.time[self._index], self.time[-1]))
        if self.cb_show:
            self._colorbar = self.ax.figure.colorbar(self._image, ax=self.ax)
            self._colorbar.set_label(self.cb_label)
        self._setup = True
        
    def update(self, i=None):
        """Update this axis."""
        if i is None and not self.paused:
            self._index += 1
        else:
            self._index = i
        
        if not self._setup:
            self.setup()
        
        self._image.set_data(self.cube[self._index,...])
        self._title.set_text(self.title.format(self.time[self._index], self.time[-1]))
        
        
    def pause_on_click(self, event):
        """Pause on click"""
        if event.inaxes == self.ax:
            self.paused = not self.paused
        
    def register(self):
        """Register event handlers."""
        self._connections['pause_on_click'] = self.ax.figure.canvas.mpl_connect('button_press_event', self.pause_on_click)

class PhaseSummaryPlot(object):
    """docstring for PhaseSummaryPlot"""
    def __init__(self, ax, time=None, x_label='', y_label=''):
        super(PhaseSummaryPlot, self).__init__()
        self.ax = ax
        self.x_label = x_label
        self.y_label = y_label
        self.time = time
        self._index = 0
        self.paused = False
        self._connections = {}
        self._setup = False
        
    def setup(self):
        """Set up the plot for plotting."""
        self._playbar = self.ax.axvline(0.0, color='r', linewidth=3, alpha=0.5)
        self.ax.set_ylabel(self.y_label)
        self.ax.set_xlabel(self.x_label)
        self._setup = True
        
    def update(self, i=None):
        """docstring for update"""
        if i is None and not self.paused:
            self._index += 1
        else:
            self._index = i
        
        if not self._setup:
            self.setup()
            
        vline_xdata, vline_ydata = self._playbar.get_data()
        if self.time is None:
            t = self._index
        else:
            t = self.time[self._index]
        vline_xdata[:] = np.array([t, t], dtype=np.float)
        self._playbar.set_data(vline_xdata, vline_ydata)

class PhasePlayer(pyshell.CLIEngine):
    """Play me some phase!"""
    
    defaultcfg = False
    connections = {}
    
    @staticmethod
    def fixbyteorder(array, target=None):
        """Fix the byte order of an array."""
        ordered = "<>="
        if target is None:
            sys_is_le = sys.byteorder == 'little'
            native_code = sys_is_le and '<' or '>'
            target = "=" + native_code
        if array.dtype.byteorder not in ordered:
            return array
        elif array.dtype.byteorder in target:
            return array
        elif array.dtype.byteorder not in target:
            array = array.byteswap().newbyteorder()
            if array.dtype.byteorder not in target:
                raise ValueError("Couldn't fix byteorder")
            return array
    
    def init(self):
        """Initialize!"""
        super(PhasePlayer, self).init()
        self.parser.add_argument('-o',dest="movie",default=None)
        
    def after_configure(self):
        """Add positional arguments to the file."""
        super(PhasePlayer, self).after_configure()
        self.parser.add_argument('--show',action='store_true',help="Show the movie, don't save it.")
        self.parser.add_argument('--log', action='store_true', help='Log-scale data')
        self.parser.add_argument('--sigclip', action='store_true', help='use sigma-clipped data (3sig)')
        self.parser.add_argument('--cmap', type=six.text_type, help='colormap', default='binary')
        self.parser.add_argument('--fft', action='store_true', help='FFT data before display')
        self.parser.add_argument('-v','--verbose', action='store_true', help='be verbose')
        self.parser.add_argument('--idl', help='IDL Scope to use for .sav files', default='')
        self.parser.add_argument('--hdf5', type=six.text_type, help='Data path for HDF5 files.')
        self.parser.add_argument('file', help="The input FITS file.", metavar="file.fits")
        
        
    def get_data(self, filename):
        """Get the data from the file"""
        if filename.endswith('.sav') or filename.endswith('.dat'):
            return self.get_idl_data(filename)
        elif filename.endswith('.fits') or filename.endswith('.fit') or filename.endswith('.gz'):
            return self.get_fits_data(filename)
        elif filename.endswith('.hdf5'):
            return self.get_hdf5_data(filename)
        else:
            self.log.warning("File is assumed to be FITS: '{}'".format(filename))
            return self.get_fits_data(filename)
            
    def get_fits_data(self, filename):
        """Get the data from a FITS file."""
        from astropy.io import fits
        with fits.open(filename) as HDUs:
            return self.fixbyteorder(HDUs[0].data.copy())
        
    def get_idl_data(self, filename):
        """Read the data from an IDL save file."""
        from scipy.io.idl import readsav
        scope = readsav(filename)
        if is_type(self.opts.idl, int):
            data = scope[scope.keys()[self.opts.idl]]
        else:
            data = scope[self.opts.idl]
        if isinstance(data, np.ndarray):
            return data
        else:
            self.log.critical("Data is not an ndarray.")
            raise ValueError("Data: {!r}".format(data))
        
    def get_hdf5_data(self, filename):
        """Read the data from an HDF5 file."""
        import h5py
        with h5py.File(filename) as f:
            d = f.get(self.opts.hdf5)
            return d[...]
    
        
    def _setup_matplotlib(self):
        """Setup the matploblit environment"""
        import matplotlib
        if self.opts.show:
            matplotlib.use('Qt4Agg')
        else:
            matplotlib.use('Agg')
        
        matplotlib.rcParams['text.usetex'] = False
        matplotlib.rcParams['savefig.dpi'] = 300
        
        if self.opts.verbose:
            from matplotlib import verbose
            verbose.set_level('debug')
        
    def do(self):
        """Run the phase screen."""
        self._setup_matplotlib()
        
        from astropy.utils.console import ProgressBar
        import matplotlib.pyplot as plt
        from matplotlib import animation
        from matplotlib.colors import SymLogNorm, Normalize
        from matplotlib.gridspec import GridSpec
        
        if self.opts.movie is None:
            self.opts.movie = os.path.splitext(self.opts.file[0])[0] + '.mp4'
        
        self.ntime = 0
        self.data = self.get_data(self.opts.file)
        if self.opts.fft:
            import scipy.fftpack
            self.data = np.abs(scipy.fftpack.fftshift(scipy.fftpack.fftn(self.data, axes=(1,2)), axes=(1,2)))
        self.ntime = self.data.shape[0]
        
        if self.opts.sigclip:
            sigma = np.std(self.data)
            mean = np.mean(self.data)
            vlim = (mean - 3 * sigma, mean + 3 * sigma)        
        else:
            vlim = (np.min(self.data),np.max(self.data))
        
        if self.opts.log:
            print(np.min(np.abs(self.data[self.data != 0.0])))
            norm = SymLogNorm(1.0, linscale=0.01, vmin = vlim[0], vmax = vlim[1])
        else:
            norm = Normalize(vmin = vlim[0], vmax = vlim[1])
        
        self.fig = plt.figure(figsize=(9,9))
        
        gs = GridSpec(2, 1, height_ratios=[1, 0.25])
        
        rms_ax = self.fig.add_subplot(gs[1,:])
        self.rms = PhaseSummaryPlot(rms_ax, x_label='Time', y_label="RMS nm of phase error")
        
        rms_ax.plot(np.std(self.data, axis=(1,2)), '-')
        phase_ax = self.fig.add_subplot(gs[0,:])
        
        self.image = PhaseMovieView(phase_ax, self.data, norm = norm, cmap=self.opts.cmap)
        self.paused = False
        self.index = 0
        
        self.anim = animation.FuncAnimation(self.fig, self.animate, frames=self.data.shape[0], interval=1)
        if self.opts.show:
            print("Showing Phase in live window")
            self.connections["mouse_press"] = self.fig.canvas.mpl_connect('button_press_event', self.on_click)
            self.connections["key_press"] = self.fig.canvas.mpl_connect('key_press_event', self.on_key)
            with ProgressBar(self.data.shape[0], file=object() if self.opts.verbose else None) as self.pbar:
                plt.show()
        else:
            print("Writing Movie...")
            with ProgressBar(self.data.shape[0], file=object() if self.opts.verbose else None) as self.pbar:
                self.anim.save(self.opts.movie, fps=30, writer='ffmpeg')
        
    def animate(self,n):
        """Animate the screen!"""
        if not self.paused and self.index < self.ntime - 1:
            self.index += 1
        self.image.update(self.index)
        self.rms.update(self.index)
        if hasattr(self,'pbar'):
            self.pbar.update(self.index)
    
    def on_click(self, event):
        """On click button press handler."""
        if (event.inaxes != self.rms.ax):
            self.paused = not self.paused
        elif (event.inaxes == self.rms.ax):
            self.index = event.xdata
    
    def on_key(self, event):
        """On key"""
        import matplotlib.pyplot as plt
        if event.key in ["q","Q"]:
            self.anim._stop()
            plt.close(self.fig)
        if event.key in [" "]:
            self.paused = not self.paused
        if event.key in ["left"] and self.index > 0:
            self.index -= 1
        if event.key in ["right"] and self.index < self.ntime - 1:
            self.index += 1

if __name__ == '__main__':
    PhasePlayer.script()
