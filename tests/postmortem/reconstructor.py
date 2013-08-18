#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  reconstructor.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-08-14.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 


import os, os.path, glob
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec

postmortem_data = os.path.join(os.path.dirname(__file__),"data")

for ending in ["","_ap","_sm"]:
    modes = glob.glob(os.path.join(postmortem_data,"zs_idl_mod_hud_[0-9]_[-0-9]{:s}.npy".format(ending)))
    modes = [ (int(path.split(".")[1].split("_")[4]),int(path.split(".")[1].split("_")[5])) for path in modes ]

    for n,m in modes:
    
        idl_fn = os.path.join(postmortem_data, "zs_idl_mod_hud_{n:d}_{m:d}{ending:s}.npy".format(n=n,m=m,ending=ending))
        pyt_fn = os.path.join(postmortem_data, "zs_pyt_mod_hud_{n:d}_{m:d}{ending:s}.npy".format(n=n,m=m,ending=ending))
    
        zs_idl = np.load(idl_fn)
        zs_pyt = np.load(pyt_fn)
    
        gs = GridSpec(1,2)
    
        fig = plt.figure()
        fig.suptitle("({:d},{:d})".format(n,m))
        ax_idl = fig.add_subplot(gs[0,0])
        ax_idl.get_xaxis().set_visible(False)
        ax_idl.get_yaxis().set_visible(False)
        ax_idl.imshow(zs_idl)
    
        ax_pyt = fig.add_subplot(gs[0,1])
        ax_pyt.get_xaxis().set_visible(False)
        ax_pyt.get_yaxis().set_visible(False)
        ax_pyt.imshow(zs_pyt)
    
plt.show()
