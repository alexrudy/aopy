# -*- coding: utf-8 -*-
# 
#  core.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-04-29.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)


from pyshell.pipeline import Pipeline
from pyshell.pipeline._oldhelp import *
import pyshell



class WCAOPipeline(Pipeline):
    """A pipeline to handle WCAO Simulations"""
    
    supercfg = pyshell.PYSHELL_LOGGING_STREAM
    
    defaultcfg = "wcao.yml"
    
    def init(self):
        """docstring for init"""
        super(WCAOPipeline, self).init()
        self.collect()
        
        
    
    def make_screen(self):
        """Setup Screen"""
        from aopy.atmosphere.wind import ManyLayerScreen
        self.screen = ManyLayerScreen(
            tuple(self.config["Instrument.shape"]),
            self.config["Screen.r0"],
            seed=self.config.get("Screen.seed",None),
            du=self.config["Instrument.du"],
            vel=self.config["Wind.velocity"],
            tmax=self.config["Screen.tmax"]).setup()
        
    @depends('make_screen')
    def fill_screen(self):
        """Fill out screen data"""
        from astropy.utils.console import ProgressBar
        import numpy as np
        self.screen_data = np.zeros((self.config["Simulation.tmax"],)+tuple(self.config["Instrument.shape"]))
        for i in ProgressBar(range(self.config["Simulation.tmax"])):
            self.screen_data[i,...] = self.screen.get_screen(i)
            
    @depends('fill_screen')
    def save_screen(self):
        """Save Screen to File"""
        from astropy.io import fits
        fits.writeto(self.config["Wind.filename"],self.screen_data,clobber=True)
    
    def results_struct(self):
        """Make results structure"""
        self.results = {}
        
    def setup_plot(self):
        """Setup plot structure"""
        self.figures = {}
    
    @depends("fill_screen","results_struct")
    def gn_normal(self):
        """GaussNewton"""
        import numpy as np
        from wcao.estimators.gaussnewton import GaussNewtonEstimator
        from wcao.analysis.data import WCAOTimeseries
        
        results = np.zeros((self.config["Simulation.tmax"],2))
        plan = GaussNewtonEstimator().setup(np.ones(tuple(self.config["Instrument.shape"])))
        results = self.run_from_plan(plan,lambda i : (self.screen_data[i,...],self.screen_data[i-1,...]))
        self.results["GaussNewton"] = WCAOTimeseries("GN","","Sim",results)
        
        
    @depends("fill_screen","results_struct")
    def gn_fft(self):
        """GaussNewton in FFT space"""
        import numpy as np
        from wcao.estimators.gaussnewton import GaussNewtonEstimator
        from wcao.analysis.data import WCAOTimeseries
        
        results = np.zeros((self.config["Simulation.tmax"],2))
        plan = GaussNewtonEstimator(fft=True).setup(np.ones(tuple(self.config["Instrument.shape"])))
        results = self.run_from_plan(plan,lambda i : (self.screen_data[i,...],self.screen_data[i-1,...]))
        self.results["GaussNewton FFT"] = WCAOTimeseries("GN","FFT","Sim",results)
        
    @depends("fill_screen","results_struct")
    def gn_idl(self):
        """GaussNewton with IDL-like Convolve"""
        import numpy as np
        from wcao.estimators.gaussnewton import GaussNewtonEstimator
        from wcao.analysis.data import WCAOTimeseries
        plan = GaussNewtonEstimator(fft=False,idl=True).setup(np.ones(tuple(self.config["Instrument.shape"])))
        results = self.run_from_plan(plan,lambda i : (self.screen_data[i,...],self.screen_data[i-1,...]))
        self.results["GaussNewton IDL-like"] = WCAOTimeseries("GN","IDL-like","Sim",results)
        
    @depends("save_screen","results_struct")
    def gn_pidly(self):
        """GaussNewton via pIDLy"""
        import numpy as np
        from wcao.estimators.pidly.estimate_wind_gn import GaussNewtonPIDLY
        from wcao.analysis.data import WCAOTimeseries
        plan = GaussNewtonPIDLY(
            astron_path=self.config["IDL.astron.path"],
            filename=self.config["Wind.filename"]
            ).setup(np.ones(tuple(self.config["Instrument.shape"])))
        results = self.run_from_plan(plan,lambda i : (i,))
        self.results["GaussNewton pIDLy"] = WCAOTimeseries("GN","pIDLy","Sim",results)
        
    def run_from_plan(self,plan,argfunc):
        """Run from a plan."""
        from astropy.utils.console import ProgressBar
        import numpy as np
        results = np.zeros((self.config["Simulation.tmax"],plan.nlayers,2))
        for i in ProgressBar(xrange(self.config["Simulation.tmax"])):
            results[i,:] = plan.estimate(*argfunc(i))
        return results
        
    @depends("gn_normal","gn_fft","gn_pidly","gn_idl")
    def gn(self):
        """All GaussNewton Methods"""
        import numpy as np
        # for label, res in self.results.items():
        #     self.log.info("{:30s}: [{:7.2g},{:7.2g}]".format(label,*np.mean(res.data[:,0,:],axis=0)))
        
        
    @depends("gn","setup_plot")
    def plot_gn_ts(self):
        """Plot GaussNewton"""
        import matplotlib.pyplot as plt
        import numpy as np
        fig = plt.figure()
        for r,c in zip(self.results.values(),"bgryc"[:len(self.results)]):
            r.threepanelts(fig,color=c)
        self.figures["GNTS"] = fig
        
    @depends("gn","setup_plot")
    def plot_gn_map(self):
        """Make a map of Gauss-Newton Data"""
        from .visualize import make_circles
        import matplotlib.pyplot as plt
        import numpy as np
        fig = plt.figure()
        limits = (self.config["Maps.Limits.min"],self.config["Maps.Limits.max"])
        circles = np.linspace(0,max(limits),5,endpoint=True)[1:]
        n = np.ceil(np.sqrt(len(self.results)))
        for i,r in enumerate(self.results.values()):
            ax = fig.add_subplot(n,n,i+1)
            r.map(ax,size=max(limits))
            [ ax.add_artist(a) for a in make_circles(circles,color=self.config.get("Maps.Grid.color","k")) ]
            ax.set_xlim(limits)
            ax.set_ylim(limits)
        
    def show(self):
        """Show GaussNewton Plots"""
        import matplotlib.pyplot as plt
        plt.show()

        