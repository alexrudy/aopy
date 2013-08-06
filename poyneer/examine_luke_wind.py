#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  examine_luke_wind.py
#  telem_analysis_13
#  
#  Created by Jaberwocky on 2013-03-11.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 

from __future__ import division
import matplotlib.pyplot as plt
import numpy as np
import pyfits as pf
import os.path, glob

from pyshell.util import query_string, is_type_factory, check_exists
from plot_luke_wind import PlotLukeWind, select_files

class ExamineWind(PlotLukeWind):
    """docstring for ExamineWind"""
    
    def do(self):
        """Take action!"""
        files = glob.glob("data/**/proc/*_wind.fits")
        if len(self.opts.name) == 0:
            self.opts.name = select_files(files,allow_all=False)
        if len(self.opts.name) != 1:
            self.parser.error()
        FileNames = []
        for fname in self.opts.name:
            if is_type_factory(int)(fname):
                FileNames.append(files[fname])
            elif isinstance(fname,basestring) and check_exists(fname):
                FileNames.append(fname)
            else:
                print("Skipping File '{}'".format(fname))
                
        FModeName = FileNames[0].rstrip("_wind.fits")+"_fwmap.fits"
        print("Opening Data File '{}'".format(FileNames[0]))
        DataFile = pf.open(FileNames[0])
        print("Opening Data File '{}'".format(FModeName))
        FModeMap = pf.open(FModeName)
        Wind = DataFile[0].data[:,:2,:]
        Time = DataFile[0].data[:,2,:]
        from IPython.frontend.terminal.embed import InteractiveShellEmbed
        shell = InteractiveShellEmbed(banner1="Starting IPython Interpreter with variables:\n"\
        "'Wind','Time','DataFile','FModeMap'")
        shell()
        
if __name__ == '__main__':
    ExamineWind.script()