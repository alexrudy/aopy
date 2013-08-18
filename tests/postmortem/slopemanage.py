#!/usr/bin/env python
# 
#  slopemanage.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-08-15.
#  Copyright 2013 Alexander Rudy. All rights reserved.
#

import os, os.path, glob
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec

postmortem_data = os.path.join(os.path.dirname(__file__),"data")

modes = glob.glob(os.path.join(postmortem_data,"xs_sm_idl_*.npy"))
modes = [ (int(path.split(".")[1].split("_")[3]),int(path.split(".")[1].split("_")[4])) for path in modes ]

for n,m in modes:
    
    x_idl_fn = os.path.join(postmortem_data, "xs_sm_idl_{n:d}_{m:d}.npy".format(n=n,m=m))
    x_pyt_fn = os.path.join(postmortem_data, "xs_sm_pyt_{n:d}_{m:d}.npy".format(n=n,m=m))
    y_idl_fn = os.path.join(postmortem_data, "ys_sm_idl_{n:d}_{m:d}.npy".format(n=n,m=m))
    y_pyt_fn = os.path.join(postmortem_data, "ys_sm_pyt_{n:d}_{m:d}.npy".format(n=n,m=m))
    
    xs_idl = np.load(x_idl_fn)
    xs_pyt = np.load(x_pyt_fn)
    ys_idl = np.load(y_idl_fn)
    ys_pyt = np.load(y_pyt_fn)
    xs_dif = xs_idl - xs_pyt
    ys_dif = ys_idl - ys_pyt
    
    gs = GridSpec(2,3)
    
    fig = plt.figure()
    
    ax_x_idl = fig.add_subplot(gs[0,0])
    ax_x_idl.get_xaxis().set_visible(False)
    ax_x_idl.get_yaxis().set_visible(False)
    ax_x_idl.imshow(xs_idl)
    ax_y_idl = fig.add_subplot(gs[1,0])
    ax_y_idl.get_xaxis().set_visible(False)
    ax_y_idl.get_yaxis().set_visible(False)
    ax_y_idl.imshow(ys_idl)
    
    ax_x_pyt = fig.add_subplot(gs[0,1])
    ax_x_pyt.get_xaxis().set_visible(False)
    ax_x_pyt.get_yaxis().set_visible(False)
    ax_x_pyt.imshow(xs_pyt)
    ax_y_pyt = fig.add_subplot(gs[1,1])
    ax_y_pyt.get_xaxis().set_visible(False)
    ax_y_pyt.get_yaxis().set_visible(False)
    ax_y_pyt.imshow(ys_pyt)
    
    ax_x_dif = fig.add_subplot(gs[0,2])
    ax_x_dif.get_xaxis().set_visible(False)
    ax_x_dif.get_yaxis().set_visible(False)
    ax_x_dif.imshow(xs_dif)
    ax_y_dif = fig.add_subplot(gs[1,2])
    ax_y_dif.get_xaxis().set_visible(False)
    ax_y_dif.get_yaxis().set_visible(False)
    ax_y_dif.imshow(ys_dif)
    
    
plt.show()
