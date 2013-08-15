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
ipydb()

import glob
import os.path

def make_axes(ax, title):
    """docstring for make_axes"""
    ax.get_xaxis().set_visible(False)
    ax.get_yaxis().set_visible(False)
    if title:
        ax.set_title(title)

    
files = glob.glob("zs_sm_idl_[0-9]*_[-0-9]*.npy")
modes = []
for file in files:
    base, ext = os.path.splitext(file)
    tokens = base.split("_")
    n = int(tokens[3])
    m = int(tokens[4])
    modes.append((n,m))
    
for n,m in modes:
    
    from aopy.wavefront.zernike import zernike_cartesian
    
    rtol = 1e-4
    atol = 0.1
    
    npy_filename = "zs_sm_idl_{n:d}_{m:d}.npy".format(n=n,m=m)
    pyt_filename = "zs_sm_pyt_{n:d}_{m:d}.npy".format(n=n,m=m)
    
    xs_npy, ys_npy = np.dsplit(np.load(npy_filename),2)
    xs_pyt, ys_pyt = np.dsplit(np.load(pyt_filename),2)
    xs_npy = xs_npy[...,0]
    ys_npy = ys_npy[...,0]
    xs_pyt = xs_pyt[...,0]
    ys_pyt = ys_pyt[...,0]
    x_dif = xs_npy-xs_pyt
    y_dif = ys_npy-ys_pyt
    xs_ok = np.abs(xs_npy-xs_pyt) <= atol + rtol * np.abs(xs_pyt)
    ys_ok = np.abs(ys_npy-ys_pyt) <= atol + rtol * np.abs(ys_pyt)
    
    vmin = np.min([np.min(xs_npy),np.min(xs_pyt),np.min(ys_npy),np.min(ys_pyt)])
    vmax = np.max([np.max(xs_npy),np.max(xs_pyt),np.max(ys_npy),np.max(ys_pyt)])
    vdmin = np.min([x_dif, y_dif])
    vdmax = np.max([x_dif, y_dif])
    
    size = xs_npy.shape[0]
    
    X, Y = np.mgrid[-size/2:size/2,-size/2:size/2] / 19.0
    zs_can = zernike_cartesian(n, m, X, Y)
    xs_can, ys_can = np.gradient(zs_can)
    
    fig = plt.figure(figsize=(8,4))
    gs = gridspec.GridSpec(2,5)
    
    ax_xnpy = fig.add_subplot(gs[0,0])
    make_axes(ax_xnpy,"X-({n},{m}) IDL".format(n=n,m=m))
    im_xnpy = ax_xnpy.imshow(xs_npy, vmin=vmin, vmax=vmax)
    
    ax_xpyt = fig.add_subplot(gs[0,1])
    make_axes(ax_xpyt,"X-({n},{m}) Python".format(n=n,m=m))
    im_xpyt = ax_xpyt.imshow(xs_pyt, vmin=vmin, vmax=vmax)
    
    ax_ynpy = fig.add_subplot(gs[1,0])
    make_axes(ax_ynpy,"Y-({n},{m}) IDL".format(n=n,m=m))
    im_ynpy = ax_ynpy.imshow(ys_npy, vmin=vmin, vmax=vmax)
    
    ax_ypyt = fig.add_subplot(gs[1,1])
    make_axes(ax_ypyt,"Y-({n},{m}) Python".format(n=n,m=m))
    im_ypyt = ax_ypyt.imshow(ys_pyt, vmin=vmin, vmax=vmax)
    
    fig.colorbar(im_xpyt, ax=[ax_xnpy,ax_ynpy,ax_xpyt,ax_ypyt])
    
    ax_xcan = fig.add_subplot(gs[0,2])
    make_axes(ax_xcan,"X-({n},{m}) Canonical".format(n=n,m=m))
    im_xcan = ax_xcan.imshow(xs_can)
    
    ax_ycan = fig.add_subplot(gs[1,2])
    make_axes(ax_ycan,"Y-({n},{m}) Canonical".format(n=n,m=m))
    im_ycan = ax_ycan.imshow(ys_can)
    
    fig.colorbar(im_ycan, ax=[ax_xcan, ax_ycan])
    
    ax_xdif = fig.add_subplot(gs[0,3])
    make_axes(ax_xdif,"X-({n},{m}) IDL-Python".format(n=n,m=m))
    im_xdif = ax_xdif.imshow(x_dif, vmin=vdmin, vmax=vdmax)
    ax_ydif = fig.add_subplot(gs[1,3])
    make_axes(ax_ydif,"Y-({n},{m}) IDL-Python".format(n=n,m=m))
    im_ydif = ax_ydif.imshow(y_dif, vmin=vdmin, vmax=vdmax)
    
    ax_xbad = fig.add_subplot(gs[0,4])
    make_axes(ax_xbad,"X-({n},{m}) Failing".format(n=n,m=m))
    x_dif[xs_ok] = np.nan
    im_xbad = ax_xbad.imshow(x_dif, vmin=vdmin, vmax=vdmax) 
    ax_ybad = fig.add_subplot(gs[1,4])
    make_axes(ax_ybad,"Y-({n},{m}) Failing".format(n=n,m=m))
    y_dif[ys_ok] = np.nan
    im_ybad = ax_ybad.imshow(y_dif, vmin=vdmin, vmax=vdmax) 
    
    fig.colorbar(im_xdif, ax=[ax_xdif,ax_xbad,ax_ydif,ax_ybad])
    
plt.show()