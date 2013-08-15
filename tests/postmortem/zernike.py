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

files = glob.glob("z_npy_[0-9]*_[-0-9]*.dat")
modes = []
for file in files:
    base, ext = os.path.splitext(file)
    tokens = base.split("_")
    n = int(tokens[2])
    m = int(tokens[3])
    modes.append((n,m))
    
for n,m in modes:
    
    rtol = 1e-8
    atol = 1e-4
    
    npy_filename = "z_npy_{n:d}_{m:d}.dat".format(n=n,m=m)
    pyt_filename = "z_pyt_{n:d}_{m:d}.dat".format(n=n,m=m)
    
    z_npy = np.loadtxt(npy_filename)
    z_pyt = np.loadtxt(pyt_filename)
    z_dif = z_npy-z_pyt
    z_ok = np.abs(z_npy-z_pyt) <= atol + rtol * np.abs(z_pyt)
    
    
    vmin = np.min([np.min(z_npy),np.min(z_pyt)])
    vmax = np.max([np.max(z_npy),np.max(z_pyt)])
    
    fig = plt.figure(figsize=(8,4))
    ax_npy = fig.add_subplot(2,2,1)
    ax_npy.get_xaxis().set_visible(False)
    ax_npy.get_yaxis().set_visible(False)
    ax_npy.set_title("({n},{m}) IDL/don".format(n=n,m=m))
    im_npy = ax_npy.imshow(z_npy, vmin=vmin, vmax=vmax)
    
    ax_pyt = fig.add_subplot(2,2,3)
    ax_pyt.get_xaxis().set_visible(False)
    ax_pyt.get_yaxis().set_visible(False)
    ax_pyt.set_title("({n},{m}) Python".format(n=n,m=m))
    im_pyt = ax_pyt.imshow(z_pyt, vmin=vmin, vmax=vmax)
    
    fig.colorbar(im_pyt, ax=[ax_npy,ax_pyt])
    
    ax_dif = fig.add_subplot(2,2,2)
    ax_dif.get_xaxis().set_visible(False)
    ax_dif.get_yaxis().set_visible(False)
    ax_dif.set_title("({n},{m}) IDL-Python".format(n=n,m=m))
    im_dif = ax_dif.imshow(z_dif)
    
    ax_bad = fig.add_subplot(2,2,4)
    ax_bad.get_xaxis().set_visible(False)
    ax_bad.get_yaxis().set_visible(False)
    ax_dif.set_title("({n},{m}) Failing".format(n=n,m=m))
    z_dif[z_ok] = np.nan
    im_bad = ax_bad.imshow(z_dif) 
    
    fig.colorbar(im_dif, ax=[ax_dif,ax_bad])
    
files = glob.glob("zs_npy_[0-9]*_[-0-9]*.npy")
modes = []
for file in files:
    base, ext = os.path.splitext(file)
    tokens = base.split("_")
    n = int(tokens[2])
    m = int(tokens[3])
    modes.append((n,m))
    
for n,m in modes:
    
    from aopy.wavefront.zernike import zernike_cartesian
    
    rtol = 1e-4
    atol = 0.1
    
    npy_filename = "zs_npy_{n:d}_{m:d}.npy".format(n=n,m=m)
    pyt_filename = "zs_pyt_{n:d}_{m:d}.npy".format(n=n,m=m)
    
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
    ys_can, xs_can = np.gradient(zs_can)
    
    fig = plt.figure(figsize=(8,4))
    gs = gridspec.GridSpec(2,5)
    
    ax_xnpy = fig.add_subplot(gs[0,0])
    make_axes(ax_xnpy,"X-({n},{m}) NPY/Gradient".format(n=n,m=m))
    im_xnpy = ax_xnpy.imshow(xs_npy, vmin=vmin, vmax=vmax)
    
    ax_xpyt = fig.add_subplot(gs[0,1])
    make_axes(ax_xpyt,"X-({n},{m}) Python".format(n=n,m=m))
    im_xpyt = ax_xpyt.imshow(xs_pyt, vmin=vmin, vmax=vmax)
    
    ax_ynpy = fig.add_subplot(gs[1,0])
    make_axes(ax_ynpy,"Y-({n},{m}) NPY/Gradient".format(n=n,m=m))
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