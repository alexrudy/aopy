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
    
    supercfg = pyshell.PYSHELL_LOGGING_STREAM + [('wcao.data','telemetry.yml')]
    
    defaultcfg = "wcao.yml"
    
    def init(self):
        """Start up the pipeline."""
        super(WCAOPipeline, self).init()
        self.collect()
        
        
    def select_instrument(self):
        """UI: Select a telemetry instrument"""
    pass
        
    def select_case(self):
        """UI: Select a telemetry data case."""
        pass
        
    def load_case(self):
        """Loading case."""
        from wcao.data.core import WCAOCase
        self.data = WCAOCase(self.config["Instrument.name"],self.config["Instrument.case"])

        