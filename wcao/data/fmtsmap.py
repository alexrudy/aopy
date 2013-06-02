# -*- coding: utf-8 -*-
# 
#  fmtsmap.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-31.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)
import numpy as np

from .estimator import WCAOEstimate
from ..estimators.fmts import FourierModeEstimator

class WCAOFMTSMap(WCAOEstimate):
    """docstring for WCAOFMTSMap"""
    def __init__(self, *args, **kwargs):
        super(WCAOFMTSMap, self).__init__(*args, **kwargs)
    
    def _init_data(self,plan):
        """Initialize the map data"""
        if plan is None:
            return
        if not isinstance(plan,FourierModeEstimator):
            raise ValueError("{:s} requires an instance of {:s} as data. Got {:s}".format(self.__class__.__name__,FourierModeEstimator.__name__,type(plan)))
        
        self.psd = plan.psd
        self.hz = plan.hz
        self.rate = plan.rate
        
        self.peaks = plan.peaks
        self.npeaks = plan.npeaks
        
        self.fit_config = plan.config["fitting"]
        
        self.metric = plan.metric
        self.possible = plan.possible
        self.matched = plan.matched
        self.match_info = plan.match_info
        
        self.layers = plan.layers
        
        
    @property
    def omega(self):
        """docstring for omega"""
        return (self.hz / self.rate) * 2.0 * np.pi
    
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
    
    def _spf_format(self,ax,data,do_label=True,do_scale=True,do_cbar=True,**kwargs):
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
        ax.set_xlabel(r"$f_x\; \mathrm{(m^{-1})}$")
        ax.set_ylabel(r"$f_y\; \mathrm{(m^{-1})}$")
        return cbar
    
    def _metric_format(self,ax,data,do_label=True,do_scale=True,do_cbar=True,**kwargs):
        """docstring for _metric_format"""
        if do_scale:
            extent = [np.min(self.match_info["vv"]),np.max(self.match_info["vv"])] * 2
        image = ax.imshow(data,extent=extent,interpolation=kwargs.pop('interpolation','nearest'),**kwargs)
        if do_cbar:
            cbar = ax.figure.colorbar(image)
        else:
            cbar = None
        ax.set_xlabel(r"$v_x\; \mathrm{(m/s)}$")
        ax.set_ylabel(r"$v_y\; \mathrm{(m/s)}$")
        return cbar
    
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
        
        search_radius = self.fit_config["search_radius"]
        mask_radius = self.fit_config["mask_radius"]
        
        for i,peak in enumerate(peaks):
            
            # This peak
            peak_hz = peak["omega"] * self.rate / (2.0 * np.pi)
            self.log.debug("Plotting peak %d, alpha=%g, hz=%g, power=%g" % (i, peak["alpha"], peak_hz, peak["variance"]))
            
            # The line that curvefit was aiming to find
            weights = (np.abs(self.omega - peak["omega"]) <= search_radius).astype(np.int)
            fitline, = ax.plot(self.hz,this_psd*weights,'--')
            
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
    
    def show_peaks(self,ax):
        """Show a count of the peaks at each mode."""
        peaks = np.sum(self.match_info["peaks_hz"][:,:,0,0,:] != 0,axis=-1)
        cbar = self._spf_format(ax,peaks)
        cbar.set_label("N")
        ax.set_title("Number of peaks found at each mode.")
    
    def show_fit(self,fig,residual=False):
        """Show the peakfit results at a specific layer position."""
        
        nlayers = len(self.layers)
        fig.subplots_adjust(hspace=0.5)
        self.log.info("Showing %d layers" % nlayers)
        
        
        vmin = -20
        vmax = 20
        nmin = 0
        nmax = 1
        
        nrow = 3
        ncol = nlayers + 1 if residual else nlayers
        from matplotlib.colors import ListedColormap
        list_cmap = ListedColormap(['w','r','g'], name='from_list')
        binary_cmap = ListedColormap(['w','r'], name='from_list')
        do_cbar = False
        for n,layer in enumerate(self.layers):    
            
            if n == len(self.layers) - 1:
                do_cbar = True
                
            self.log.info("Showing layer %d at v = [%.1f,%.1f]" % (n,layer['vx'],layer['vy']))
            vx,vy = layer['ivx'],layer['ivy']
            extent = [np.min(self.match_info["ff"]),np.max(self.match_info["ff"])] * 2
        
            all_peaks = np.copy(self.match_info["peaks_hz"])
            fit_peaks = all_peaks[...,0,0,0]
            for i in range(all_peaks.shape[-1]):
                matched_peaks = np.copy(self.match_info["full_matched"][:,:,vx,vy,i])
                fit_peaks[matched_peaks != 0] = all_peaks[...,0,0,i][matched_peaks != 0]
            matched_peaks = np.any(self.match_info["full_matched"][:,:,vx,vy,:],axis=-1)
            fit_peaks[~matched_peaks] = np.nan
            possible_peaks = np.copy(self.match_info["fv_layer_hz"][:,:,vx,vy])
            possible = np.copy(self.match_info["fv_possible"][:,:,vx,vy])
            possible_peaks[possible == 0] = np.nan
            ax1 = fig.add_subplot(nrow,ncol,(0*ncol+n+1))
            ax1.set_title("Fit Peaks")
            cbar = self._spf_format(ax1,fit_peaks,vmin=vmin,vmax=vmax,do_cbar=do_cbar)
            if do_cbar:
                cbar.set_label(r"$f_t\;(\mathrm{Hz})$")
        
        
            ax2 = fig.add_subplot(nrow,ncol,(1*ncol+n+1))
            ax2.set_title("Found Peaks")
            cbar = self._spf_format(ax2,matched_peaks+possible.astype(np.int),cmap=list_cmap,vmin=0,vmax=2,do_cbar=do_cbar)
            if do_cbar:
                cbar.set_ticks([2.0/6.0 * (2*x+1) for x in range(3)])
                cbar.set_ticklabels(["Not Possible","Possible","Match"])
        
            ax3 = fig.add_subplot(nrow,ncol,(2*ncol+n+1))
            ax3.set_title("Theory")
            cbar = self._spf_format(ax3,possible_peaks,vmin=vmin,vmax=vmax,do_cbar=do_cbar)
            if do_cbar:
                cbar.set_label(r"$f_t\;(\mathrm{Hz})$")
            
            x = (n*2+1)/(ncol*2)
            x = (x + 0.15)/(1.15)
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
        ax.set_title("Peak Metric")
        for i,layer in enumerate(self.layers):
            print("Plotting layer at {vx:.2f},{vy:.2f} with match {m:f}".format(**layer))
            ax.plot(layer['pvx'],layer['pvy'],'ko')
            ax.annotate("{:d}".format(i+1),(layer['pvx'],layer['pvy']),
                color='k',bbox=dict(fc='w'),xytext=(-10,10),textcoords='offset points')
            x = 0.2
            y = 0.05+0.02*len(self.layers) - i*0.02
            ax.figure.text(x,y,
                "%d) Layer at v = [%.1f,%.1f], matching %.1f\%%" % (i+1,layer["vx"],layer['vy'],layer["m"]*100))
        cbar.set_label(r"\% Match")
        
    def show_mask(self,ax):
        """docstring for show_mask"""
        ax.set_title("Peak Mask")
        cbar = self._metric_format(ax,self.possible)
        cbar.set_label("N")
    

        
