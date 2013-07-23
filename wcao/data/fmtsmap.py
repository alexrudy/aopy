# -*- coding: utf-8 -*-
# 
#  fmtsmap.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-31.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
"""
:mod:`wcao.data.fmtsmap` – FMTS Map Display Software
====================================================

.. autoclass::
    WCAOFMTSMap
    :members:
    :private-members:

"""

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)
import numpy as np

import datetime
import os.path

from .estimator import WCAOEstimate, set_result_header_values, read_result_header_values
from .fmtsutil import *


class WCAOFMTSMap(WCAOEstimate):
    """A representation of a FMTS Wind Estimate."""
    def __init__(self, *args, **kwargs):
        super(WCAOFMTSMap, self).__init__(*args, **kwargs)
    
    def _init_data(self,plan):
        """Initialize the map data"""
        from ..estimators.fmts import FourierModeEstimator
        
        if plan is None:
            self._initialize()
        elif isinstance(plan, FourierModeEstimator):
            self._init_from_plan(plan)
        elif isinstance(plan, basestring):
            self._init_from_files(plan)
        else:
            raise ValueError("{:s} requires an instance of {:s} as data. Got {:s}".format(self.__class__.__name__, FourierModeEstimator.__name__, type(plan)))
        
        
    def _initialize(self):
        """Initialize all of the data structures."""
        from pyshell.config import StructuredConfiguration
        self.psd = None
        self.hz = None
        self.rate = None
        
        self.peaks = None
        self.npeaks = None
        
        self.fmts_config = StructuredConfiguration()
        
        self.metric = None
        self.possible = None
        self.matched = None
        self.match_info = {}
        
    def _init_from_plan(self,plan):
        """Initialize this results object from a plan."""
        
        # Periodogram Data
        self.psd = plan.psd
        self.hz = plan.hz
        self.rate = plan.rate
        
        # Peaks Data
        self.peaks = plan.peaks
        self.npeaks = plan.npeaks
        
        # Configuration Data
        self.fmts_config = plan.config["FMTS"]
        
        # Metric Data
        self.metric = plan.metric
        self.possible = plan.possible
        self.matched = plan.matched
        self.match_info = plan.match_info
        
        # Layer Data
        self.layers = plan.layers
        
    def _init_from_files(self,filename):
        """Initialize this results object from a set of files."""
        self._load_from_files(filename)
        
    def _save_to_files(self,filename_root,clobber=False):
        """Save all of the data for this object to files.
        
        :param filename_root: The root filename
        
        """
        filename, ext  = os.path.splitext(filename_root)
        self._save_configuration(filename+".yml", clobber)
        self._save_periodogram(filename+"_periodogram.fits", clobber)
        self._save_peaks(filename+"_peaks.fits", clobber)
        self._save_metric(filename+'_metric.fits', clobber)
        self._save_match_info(filename+"_match.fits", clobber)
        self._save_layer_info(filename+"_layers.fits", clobber)
        
    def _save_single(self, filename, clobber=False):
        """docstring for _save_single"""
        from astropy.io import fits
        HDUs = fits.HDUList([set_fmts_header_values(fits.PrimaryHDU(),"primary")])
        HDUs.append(save_fmts_map(self.metric,self.match_info["vv"],self.match_info["vv"],'metric'))
        HDUs.append(save_periodogram(self.psd,self.rate))
        HDUs.append(save_peaks(self.peaks,self.npeaks))
        HDUs += save_match_info(self.match_info)
        HDUs.append(save_layer_info(self.layers))
        for HDU in HDUs:
            set_result_header_values(HDU, self.case, self.config)
        HDUs.writeto(self.fitsname, clobber=clobber)
        
    def _load_single(self, filename):
        """Load from a single massive fitsfile"""
        from astropy.io import fits
        with fits.open(filename) as HDUs:
            for HDU in HDUs:
                self._load_by_type(HDU)
        
    def _load_from_files(self, filename_root):
        """Load the full thing from files"""
        filename, ext = os.path.splitext(filename_root)
        self._load_configuration(filename+".yml")
        self._load_periodogram(filename+"_periodogram.fits")
        self._load_peaks(filename+"_peaks.fits")
        self._load_metric(filename+"_metric.fits")
        self._load_match_info(filename+"_match.fits")
        self._load_layer_info(filename+"_layers.fits")
        
    def _load_by_type(self, HDU):
        """Load an HDU by FMTSTYPE keyword values"""
        read_result_header_values(HDU, self.case, self.config)
        fmtstype = HDU.header["FMTSTYPE"]
        if fmtstype == "periodogram":
            self.psd, self.rate, self.hz = load_periodogram(HDU)
        elif fmtstype == "peaks":
            self.peaks, self.npeaks = load_peaks(HDU)
        elif fmtstype == "metric":
            self.metric, vx, vy = load_fmts_map(HDU,'metric')
            self.match_info['vv'] = vx
        elif fmtstype == "layers":
            self.layers = load_layer_info(HDU)
        elif fmtstype == 'primary':
            pass
        elif "FMTSKEY" in HDU.header:
            self.match_info.update(load_match_info([HDU]))
        
    def save(self, single=True, clobber=False):
        """Save this result!"""
        if single:
            self._save_configuration(self.dataname("yml"), clobber=clobber)
            self._save_single(self.fitsname, clobber=clobber)
        else:
            self._save_to_files(self.fitsname, clobber=clobber)
        
    def load(self, single=True):
        """Load this result!"""
        if single:
            self._load_configuration(self.dataname("yml"))
            self._load_single(self.fitsname)
        else:
            self._load_from_files(self.fitsname)
        
    def _save_periodogram(self,filename,clobber=False):
        """Save the periodogram to a fits file.
        
        The primary HDU contains the full ``t,k,l`` periodogram. The secondary HDU contains the frequency scale for this data. The secondary HDU could be recreated using the ``rate`` keyword in the primary header. The periodogram is stored with four axes, so reconstruction the data can be done like this::
            
            data = fitsdata[0] + 1j * fitsdata[1]
            
        
        """
        HDU = set_result_header_values(save_periodogram(self.psd, self.rate), self.case, self.config)
        HDU.writeto(filename, clobber=clobber)
        
    def _load_periodogram(self,filename):
        """Load the periodogram from a fits file.
        
        This function loads periodograms which were saved by :meth:`_save_periodogram`.
        
        """
        from astropy.io import fits
        with fits.open(filename) as HDUs:
            self._load_by_type(HDUs[0])
        
        
    def _save_peaks(self,filename,clobber=False):
        """Save found peaks to a table. The fits table is a simple way of storing the results from :func:`peaks_to_table`.
        """
        hdu = save_peaks(self.peaks,self.npeaks)
        hdu = set_result_header_values(hdu, self.case, self.config)
        hdu.writeto(filename,clobber=clobber)
        
    def _load_peaks(self, filename):
        """Loads found peaks from a fits file saved in the format of :meth:`_save_peaks_to_table`."""
        from astropy.io import fits
        with fits.open(filename) as HDUs:
            self._load_by_type(HDUs[1])
            
    def _save_configuration(self, filename, clobber=False):
        """Save the FMTS configuration values"""
        if os.path.exists(filename) and not clobber:
            raise IOError("Cannot overwrite {0:s}, already exists!".format(filename))
        self.fmts_config.save(filename)
        
    def _load_configuration(self, filename):
        """docstring for _load_configuration"""
        from pyshell.config import StructuredConfiguration
        self.fmts_config = StructuredConfiguration.fromfile(filename)
        
    def _save_metric(self, filename, clobber):
        """Saves the minimum amount of information to reconstruct a given metric."""
        hdu = save_fmts_map(self.metric,self.match_info["vv"],self.match_info["vv"],'metric')
        hdu = set_result_header_values(hdu, self.case, self.config)
        hdu.writeto(filename, clobber=clobber)
        
    def _load_metric(self, filename):
        """docstring for _load_metric"""
        from astropy.io import fits
        with fits.open(filename) as HDUs:
            self._load_by_type(HDUs[0])
        
    
    def _save_match_info(self, filename, clobber=False):
        """Save all the data in the match info dictionary to a file."""
        from astropy.io import fits
        HDUs = fits.HDUList([set_fmts_header_values(fits.PrimaryHDU(),"primary")] + save_match_info(self.match_info))
        for HDU in HDUs:
            set_result_header_values(HDU, self.case, self.config)
        HDUs.writeto(filename, clobber=clobber)
        
        
    def _load_match_info(self, filename, clobber=False):
        """Load the massive match info dictionary from a FITS file."""
        from astropy.io import fits
        with fits.open(filename) as HDUs:
            for HDU in HDUs:
                self._load_by_type(HDU)
            
    def _save_layer_info(self, filename, clobber=False):
        """Save the layer info to a FITS file."""
        table = save_layer_info(self.layers)
        set_result_header_values(table, self.case, self.config)
        table.writeto(filename, clobber=clobber)
        
    def _load_layer_info(self, filename):
        """Load layer information."""
        from astropy.io import fits
        with fits.open(filename) as HDUs:
            self._load_by_type(HDUs[1])
            
    
    @property
    def omega(self):
        """Angular Frequency :math:`\Omgea`"""
        return (self.hz / self.rate) * 2.0 * np.pi
        
    def __str__(self):
        """A line item representation of the FMTS map."""
        return "{self._datatype:<3.3s}: {layers:2d} layer{plural:s} on a map ({shape:s})".format(
            self = self,
            shape = "x".join(map(str,self.metric.shape)),
            layers = len(self.layers),
            plural = "" if len(self.layers) == 1 else "s"
        )
    
    def _show_psd(self,ax,psd,maxhz=50,do_label=True,do_scale=True,title="",**kwargs):
        """Internal method to properly format and show a PSD.
        
        :param axes ax: Axes on which to show the PSD.
        :param ndarray psd: The PSD to display.
        :param float maxhz: The maximum frequency to display.
        :param bool do_label: Do the labeling.
        :param string title: The title of this periodogram.
        :param **kwargs: Extra keyword arguments for :meth:`matplotlib.axes.Axes.plot`.
        
        """
        ax.plot(self.hz,np.real(psd),**kwargs)
        if title:
            ax.set_title("Periodogram for {title}".format(title=title))
        if do_label:
            ax.set_xlabel(r"$f_t\;(\mathrm{Hz})$")
            ax.set_ylabel(r"Power (arbitrary units)")
        if do_scale:
            ax.set_xlim(-1*maxhz,maxhz)
            ax.set_yscale('log')
            ax.autoscale(axis='y')
            ax.grid(True)
    
    
    def _spf_format(self,ax,data,do_label=True,do_scale=True,do_cbar=True,do_kl=False,**kwargs):
        """docstring for _spf_format"""
        if do_scale:
            extent = [np.min(self.match_info["ff"]),np.max(self.match_info["ff"])] * 2
        else:
            extent = None
        image = ax.imshow(data,extent=extent,interpolation=kwargs.pop('interpolation','nearest'),**kwargs)
        if do_cbar:
            cbar = ax.figure.colorbar(image)
        else:
            cbar = None
        if do_kl:
            k = data.shape[0]//2
            l = data.shape[1]//2
            ax2 = ax.twinx().twiny()
            ax2.set_xlim(-k,k)
            ax2.set_ylim(-l,l)
            ax2.set_xlabel(r"$k$")
            ax2.set_ylabel(r"$l$")
        ax.set_xlabel(r"$f_x\; \mathrm{(m^{-1})}$")
        ax.set_ylabel(r"$f_y\; \mathrm{(m^{-1})}$")
        return cbar
    
    def _metric_format(self,ax,data,do_label=True,do_scale=True,do_cbar=True,**kwargs):
        """docstring for _metric_format"""
        if do_scale:
            extent = [np.min(self.match_info["vv"]),np.max(self.match_info["vv"])] * 2
        image = ax.imshow(data.T,extent=extent,interpolation=kwargs.pop('interpolation','nearest'),origin='lower',**kwargs)
        if do_cbar:
            cbar = ax.figure.colorbar(image)
        else:
            cbar = None
        ax.set_xlabel(r"$v_x\; \mathrm{(m/s)}$")
        ax.set_ylabel(r"$v_y\; \mathrm{(m/s)}$")
        return cbar
        
    def _metric_circles(self,ax,dist=10,origin=[0,0],color='w',crosshair=True):
        """Show metric circles"""
        from matplotlib.patches import Circle
        from matplotlib.lines import Line2D
        xm,xp = ax.get_xlim()
        ym,yp = ax.get_ylim()
        rm = np.max(np.abs([xm,xp,ym,yp]))
        nc = rm//dist
        Rs = [ (n+1)*dist for n in range(int(nc)) ]
        circles = [Circle(origin,R,fc='none',ec=color,ls='dashed',zorder=0.1) for R in Rs]
        if crosshair:
            Rmax = max(Rs)
            major = [ -Rmax, Rmax ]
            minor = [ 0 , 0 ]
            coords = [ (major,minor), (minor,major)]
            for xdata,ydata in coords:
                circles.append(
                    Line2D(xdata,ydata,ls='dashed',color=color,marker='None',zorder=0.1)
                )
        [ ax.add_artist(a) for a in circles ]
        return circles
    
    def show_psd(self,ax,k,l,maxhz=50,title=None,**kwargs):
        """Show an individual PSD.
        
        :param ax: A matplotlib axes object on which to plot.
        :param int k: ``k``-mode.
        :param int l: ``l``-mode.
        :param float maxhz: The maximum ``hz`` value to display.
        :param string title: The title for this PSD. Will default to a sensible (k,l) title.
        
        """
        self.log.info("Showing PSD for k={:d} l={:d}".format(k,l))
        title = r"$k={k:d}$ and $l={l:d}$ for \verb+{case:s}+".format(k=k,l=l,case=self.case.casename) if title is None else title
        psd = self.psd[:,k,l]
        self._show_psd(ax,psd,maxhz,title=title,**kwargs)
    
    def show_peak_fit(self,ax,k,l,maxhz=50):
        """Make a plan show a specific PSD fitting routine.
        
        :param ax: A matplotlib axes object on which to plot.
        :param int k: ``k``-mode.
        :param int l: ``l``-mode.
        :param float maxhz: The maximum ``hz`` value to display.
        
        """
        import scipy.fftpack
        from ..estimators.fmts import fitter
        
        # Show the Raw PSD
        self.show_psd(ax,k,l,maxhz,label="Raw PSD")
        
        # Get the peaks
        peaks = self.peaks[k,l]
        self.log.debug("Showing %d peaks" % len(peaks))
        
        this_psd = np.real(self.psd[:,k,l])
        fit = np.zeros_like(this_psd,dtype=np.float)
        
        search_radius = self.fmts_config["fitting.search_radius"]
        mask_radius = self.fmts_config["fitting.mask_radius"]
        
        for i,peak in enumerate(peaks):
            
            # This peak
            peak_hz = peak["omega"] * self.rate / (2.0 * np.pi)
            self.log.debug("Plotting peak %d, alpha=%g, hz=%g, power=%g" % (i, peak["alpha"], peak_hz, peak["variance"]))
            
            # The line that curvefit was aiming to find
            weights = (np.abs(self.omega - peak["omega"]) <= search_radius).astype(np.int)
            fitline, = ax.plot(self.hz,this_psd*weights,'--.')
            
            # This particular fit.
            i_fit = fitter(self.omega,peak["alpha"],peak["variance"],peak["omega"])
            line, = ax.plot(self.hz,i_fit,':',label="Peak %d" % i, color=fitline.get_color())
            
            # Total Fit
            fit += i_fit
            
            # Residual
            this_psd = this_psd-fit
            this_psd[this_psd <= 0.0] = 0.0
            this_psd = this_psd * (np.abs(self.omega - peak["omega"]) >= mask_radius).astype(np.int)
            
        # End of fitting plots
        fitline, = ax.plot(self.hz,this_psd,'--',label="Residuals")
        ax.plot(self.hz,fit,"-.",label="Total Fit")
        
        ax.autoscale(axis='y')
        
        # Legend
        ax.legend(*ax.get_legend_handles_labels())
        self._header(ax.figure)
        
    
    def view_peaks(self,ax):
        """This is really a diagnostic method for examining peak values."""
        peaks_grid = np.ma.array(self.match_info["peaks_hz"][:,:,0,0,:],mask=(np.abs(self.match_info["peaks_hz"][:,:,0,0,:]) <= 2.0))
        peaks_dist = np.ma.argmin(np.ma.abs(peaks_grid),axis=-1)
        grid_dist = np.arange(self.match_info["peaks_hz"].shape[-1])[np.newaxis,np.newaxis,:]
        selection = (peaks_dist[:,:,np.newaxis] == grid_dist)
        peaks_grid = self.match_info["peaks_hz"][:,:,0,0,:][selection].reshape(self.match_info["peaks_hz"].shape[:-3])
        cbar = self._spf_format(ax,peaks_grid)
        cbar.set_label(r"$f_t\;(\mathrm{Hz})$")
        ax.set_title("Valid Peaks (at most one per spatial mode)")
        self._header(ax.figure)
    
    def show_peaks(self,ax):
        """Show a count of the peaks at each mode."""
        peaks = np.sum(self.match_info["peaks_hz"][:,:,0,0,:] != 0,axis=-1)
        from matplotlib.colors import ListedColormap,BoundaryNorm
        import matplotlib.cm
        cmap = ListedColormap([matplotlib.cm.jet(i) for i in range(matplotlib.cm.jet.N)])
        norm = BoundaryNorm(np.arange(np.max(peaks)+1) - 0.5,cmap.N)
        cbar = self._spf_format(ax,peaks,do_kl=False,cmap=cmap,norm=norm)
        cbar.set_ticks(np.arange(np.max(peaks)+1))
        cbar.set_ticklabels(map("{:d}".format,np.arange(np.max(peaks)+1)))
        cbar.set_label("N")
        ax.set_title("Number of peaks found at each mode.")
        self._header(ax.figure)
    
    def show_fit(self,fig,residual=False):
        """Show the peakfit results at a specific layer position."""
        import matplotlib.gridspec as gridspec
        nlayers = len(self.layers)
        
        self.log.info("Showing %d layers" % nlayers)
        self._header(fig)
        
        vmin = -20
        vmax = 20
        nmin = 0
        nmax = 1
        
        nrow = 3
        ncol = nlayers + 1 if residual else nlayers
        gs = gridspec.GridSpec(3,ncol,hspace=0.4)
        
        from matplotlib.colors import ListedColormap
        list_cmap = ListedColormap(['w','r','g'], name='from_list')
        binary_cmap = ListedColormap(['w','r'], name='from_list')
        
        extent = [ np.min(self.match_info["ff"]), np.max(self.match_info["ff"]) ] * 2
        fx, fy = np.meshgrid(self.match_info["ff"], self.match_info["ff"])
        dist_hz = self.fmts_config["metric.dist_hz"]
        
        valid = (np.abs(self.match_info["peaks_hz"]) >= self.fmts_config["metric.lowest_hz"])
        do_cbar = False
        for n,layer in enumerate(self.layers):    
            
            if n == len(self.layers) - 1:
                do_cbar = True
                
            self.log.info("Showing layer %d at v = [%.1f,%.1f]" % (n,layer['vx'],layer['vy']))
            vx,vy = np.argmin(np.abs(layer['vx']-self.match_info["vv"])),np.argmin(np.abs(layer['vy']-self.match_info["vv"]))
            self.log.info("[%.1f,%.1f] -> [%.1f,%.1f]" % (layer['ix'],layer['iy'],vx,vy))
            
            layer_peak_hz = layer["vx"] * fx + layer["vy"] * fy
            all_peaks = np.copy( self.match_info["peaks_hz"] )
            fit_peaks = all_peaks[...,0,0,0]
            full_match = (np.abs(layer_peak_hz[...,np.newaxis] - all_peaks[...,0,0,:]) <= dist_hz) & self.match_info["fv_possible"][...,vx,vy,np.newaxis] & valid[...,0,0,:]
            for i in range(all_peaks.shape[-1]):
                matched_peaks = np.copy(full_match[:,:,i])
                fit_peaks[matched_peaks != 0] = all_peaks[...,0,0,i][matched_peaks != 0]
            matched_peaks = self.match_info["fv_matched"][:,:,vx,vy]
            fit_peaks[~matched_peaks] = np.nan
            possible_peaks = layer_peak_hz
            possible = np.copy(self.match_info["fv_possible"][:,:,vx,vy])
            possible_peaks[possible == 0] = np.nan
            
            ax1 = fig.add_subplot(gs[0,n])
            ax1.set_title("Fit Peaks")
            cbar = self._spf_format(ax1,fit_peaks,vmin=vmin,vmax=vmax,do_cbar=do_cbar)
            if do_cbar:
                cbar.set_label(r"$f_t\;(\mathrm{Hz})$")
        
        
            ax2 = fig.add_subplot(gs[1,n])
            ax2.set_title("Found Peaks")
            cbar = self._spf_format(ax2,matched_peaks+possible.astype(np.int),cmap=list_cmap,vmin=0,vmax=2,do_cbar=do_cbar)
            if do_cbar:
                cbar.set_ticks([2.0/6.0 * (2*x+1) for x in range(3)])
                cbar.set_ticklabels(["Not Possible","Possible","Match"])
        
            ax3 = fig.add_subplot(gs[2,n])
            ax3.set_title("Theory")
            cbar = self._spf_format(ax3,possible_peaks,vmin=vmin,vmax=vmax,do_cbar=do_cbar)
            if do_cbar:
                cbar.set_label(r"$f_t\;(\mathrm{Hz})$")
            
            x = (n*2+1)/(ncol*2)
            x = (x + 0.10)/(1.10)
            y = 0.02
            fig.text(x,y,"Layer at v = [%.1f,%.1f], matching %.1f\%%" % (self.match_info["vv"][vx],self.match_info["vv"][vy],layer["m"]*100),ha='center')
            
        if residual:
            n = ncol - 1
            ax1 = fig.add_subplot(nrow,ncol,(0*ncol+n+1))
            all_peaks = np.copy(self.match_info["peaks_hz"])
            fit_peaks = np.zeros_like(all_peaks[...,0,0,0])
            for i in range(all_peaks.shape[-1]):
                not_matched_peaks = (np.copy(self.match_info["full_matched"][:,:,vx,vy,i]) == 0) & (all_peaks[...,0,0,i] != 0.0)
                fit_peaks[not_matched_peaks] = all_peaks[...,0,0,i][not_matched_peaks]
            count_peaks = np.sum(((self.match_info["full_matched"][:,:,vx,vy,:] == 0) & (all_peaks[...,0,0,:] != 0.0)).astype(np.int),axis=-1)
            fit_peaks[count_peaks == 0] = np.nan
            cbar = self._spf_format(ax1,fit_peaks,vmin=vmin,vmax=vmax,do_cbar=do_cbar)
            cbar.set_label(r"$f_t\;(\mathrm{Hz})$")
            ax1.set_title("Unmatched Peaks")
            ax2 = fig.add_subplot(nrow,ncol,(1*ncol+n+1))
            matched_peaks = np.sum(self.match_info["full_matched"][:,:,vx,vy,:],axis=-1)
            cbar = self._spf_format(ax2,count_peaks,vmin=0,vmax=all_peaks.shape[-1],do_cbar=do_cbar)
            cbar.set_label("N")
            ax2.set_title("N Unmatched Peaks")
    
    def show_metric(self,ax):
        """Show a specific metric"""
        # print(np.max(self.plan.metric),np.min(self.plan.metric))
        cbar = self._metric_format(ax,self.metric*100,vmin=0,vmax=100)
        self._metric_circles(ax)
        ax.set_title("Peak Metric")
        for i,layer in enumerate(self.layers):
            print("Plotting layer at {vx:.2f},{vy:.2f} with match {m:f}".format(**layer))
            ax.plot(layer['vx'],layer['vy'],'ko',alpha=0.2)
            ax.annotate("{:d}".format(i+1),(layer['vx'],layer['vy']),
                color='k',bbox=dict(fc='w'),xytext=(-10,10),textcoords='offset points')
            x = 0.2
            y = 0.05 + 0.02 * len(self.layers) - i * 0.02
            ax.figure.text(x,y,
                "%d) Layer at v = [%.1f,%.1f], matching %.1f\%%" % (i+1,layer["vx"],layer['vy'],layer["m"]*100))
        cbar.set_label(r"\% Match")
        self._header(ax.figure)
        
    def show_mask(self,ax):
        """docstring for show_mask"""
        ax.set_title("Peak Mask")
        cbar = self._metric_format(ax,self.possible)
        cbar.set_label("N")
        self._header(ax.figure)
        
    def make_pdf(self):
        """docstring for make_pdf"""
        import matplotlib.pyplot as plt
        from matplotlib.backends.backend_pdf import PdfPages
        
        pdf = PdfPages(self.figname("pdf",figtype="all"))

        fig = plt.figure()
        ax = fig.add_subplot(1,1,1)
        self.show_metric(ax)
        pdf.savefig(fig)

        fig = plt.figure()
        ax = fig.add_subplot(1,1,1)
        self.show_peak_fit(ax,0,5)
        pdf.savefig(fig)

        fig = plt.figure()
        self.show_fit(fig)
        pdf.savefig(fig)

        fig = plt.figure()
        ax = fig.add_subplot(1,1,1)
        self.show_peaks(ax)
        pdf.savefig(fig)

        pdf.close()
        self.log.info("Saved to {:s}".format(self.figname("pdf",figtype="all")))
        