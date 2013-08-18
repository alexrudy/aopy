#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  zernike_tests.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-08-13.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np
import matplotlib.pyplot as plt
from matplotlib import gridspec

from pyshell.util import ipydb
from pyshell.nosetests.postmortem import PostMortemScript
ipydb()

import glob
import os.path
import re

class SlopeDisplay(PostMortemScript):
    """Do the slope display."""
    
    module_ids = [ 'tests.test_zernike.test_zernike_slopes' ]
    
    filename_re = re.compile(r'([\w]+)_([\w]+)_([\d]+)_([\d-]+)')
    
    def parse_filename(self, filename):
        """docstring for parse_filename"""
        match = self.filename_re.match(filename)
        groups = match.groups()
        
        info = {
            'axes' : groups[0],
            'type' : groups[1],
            'n' : int(groups[2]),
            'm' : int(groups[3])
        }
        
        return info
    
    def do(self):
        """Actually do the hard work."""
        for key in self.test_data[self.module_ids[0]].keys():
            self.do_test(key)
        plt.show()
        
        
    def do_test(self, test):
        """Make displays for a specific test case."""
        filedata = {}
        filenames = self.test_data[self.module_ids[0]][test].keys()
        for filename in filenames:
            filedata[filename] = self.parse_filename(filename)
        
        row = { 'xs': 0, 'ys': 1 }
        col = { 'npy' : 1, 'pyt': 2, 'dif':3}
        gs = gridspec.GridSpec(2,5)
        figure = plt.figure(figsize=(8,4))
        
        for filename in filenames:
            info = filedata[filename]
            data = self.test_data[self.module_ids[0]][test][filename]
            col_pos = col.get(info['type'],0)
            row_pos = row.get(info['axes'],0)
            if info['axes'] == 'z':
                col_pos = 0
            axes = self.axes(figure, gs[row_pos,col_pos])
            self.label_axes(axes, "{:s}-{:s}-({:2d},{:2d})".format(
                info['axes'][0].capitalize(), info['type'], info['n'], info['m']
            ))
            axes.imshow(data)
        
        
    def axes(self, figure, subplotspec):
        """Return a setup axes from a subplotspec"""
        ax = figure.add_subplot(subplotspec)
        ax.get_xaxis().set_visible(False)
        ax.get_yaxis().set_visible(False)
        ax.set_frame_on(False)
        return ax
    
    def label_axes(self, ax, label):
        """Label axes above."""
        ax.text(0.5, 1.0, label, transform=ax.transAxes, va='bottom', ha='center')
    

if __name__ == '__main__':
    SlopeDisplay.script()