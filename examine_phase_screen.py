#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  examine_phase_screen.py
#  telem_analysis_13
#  
#  Created by Jaberwocky on 2013-04-04.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
from __future__ import division
import matplotlib.pyplot as plt
import numpy as np
import pyfits as pf
import os.path, glob

from pyshell import CLIEngine
from pyshell.util import query_string, is_type_factory, check_exists


class ExaminePhase(CLIEngine):
    """Examine's the phase screen."""
    
    defaultcfg = False
    
    def init(self):
        """Add appropriate arguments!"""
        super(ExaminePhase, self).init()
        self.parser.add_argument('screen',type=str,help="Phase screen to examine")
        
    def do(self):
        """Examine the phase screen!"""
        