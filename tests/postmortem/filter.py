#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  filter.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-08-14.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import os, os.path, glob
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec

def imshow_complex(ax_real, ax_imag, data):
    """Use imshow to show a complex valued data."""
    im_real = ax_real.imshow(np.real(data))
    im_imag = ax_imag.imshow(np.imag(data))
    return im_real, im_imag

def slope_plot(fig, data, s_spec_a, s_spec_b, title, label=False):
    """Plot slopes"""
    ax_real = fig.add_subplot(s_spec_a)
    ax_imag = fig.add_subplot(s_spec_b)
    imshow_complex(ax_real, ax_imag, data)
    ax_real.set_title(title)
    if label:
        ax_real.set_ylabel("Real")
        ax_imag.set_ylabel("Imaginary")

postmortem_data = os.path.join(os.path.dirname(__file__),"data")

filters = glob.glob(os.path.join(postmortem_data,"gx_idl_*.npy"))
filters = [ "_".join(path.split(".")[1].split("_")[2:]) for path in filters ]

for _filter in filters:
    print(_filter)
    gx_idl = np.load(os.path.join(postmortem_data,"gx_idl_{filter}.npy".format(filter=_filter)))
    gy_idl = np.load(os.path.join(postmortem_data,"gy_idl_{filter}.npy".format(filter=_filter)))
    gx_pyt = np.load(os.path.join(postmortem_data,"gx_pyt_{filter}.npy".format(filter=_filter)))
    gy_pyt = np.load(os.path.join(postmortem_data,"gy_pyt_{filter}.npy".format(filter=_filter)))
    
    gs = GridSpec(2,4)
    fig = plt.figure()
    slope_plot(fig, gx_idl, gs[0,0], gs[1,0], "GX-IDL", label=True)
    slope_plot(fig, gy_idl, gs[0,2], gs[1,2], "GY-IDL")
    slope_plot(fig, gx_pyt, gs[0,1], gs[1,1], "GX-PYT")
    slope_plot(fig, gy_pyt, gs[0,3], gs[1,3], "GY-PYT")

if len(filters) == 0:
    print("No postmortem filter data found.")
plt.show()
