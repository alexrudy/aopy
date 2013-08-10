#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  try_gn_wind.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-18.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)
                        

import pidly
import os.path

from wcao.gaussnewton import estimate_wind_gn

from astropy.utils.console import ProgressBar
from astropy.io import fits

import pyshell.loggers
import pyshell

import scipy.signal
import numpy as np

from aopy.atmosphere.wind import ManyLayerScreen

log = pyshell.loggers.getSimpleLogger(__name__)

# Control Variables
shape = (5,5)
du = 10/30
r0 = 0.30
ntime = 3
wind = np.array([0,2])
log.status("Setting up screen")
Screen = ManyLayerScreen(shape,r0,seed=10,du=du,vel=[[0,0],[0,2]],tmax=ntime).setup()
screen = np.zeros((ntime,)+shape)
log.status("Writing screen to array")
with ProgressBar(ntime) as pbar:
    for i in range(ntime):
        screen[i,...] = Screen.get_screen(i)
        pbar.update(i)
fits.writeto("test_screen.fits",screen,clobber=True)
log.status("Wrote screen to file")
log.info("Launching IDL...")
IDL = pidly.IDL()
IDL('!PATH=!PATH+":"+expand_path("+~/Development/IDL/don_pro")')
luke_path = os.path.normpath(os.path.join(os.path.dirname(__file__),"..","IDL"))
IDL('!PATH=!PATH+":"+expand_path("+{:s}")'.format(luke_path))

log.info("Setting Up Environment...")
fits_path = os.path.normpath(os.path.join(os.path.dirname(__file__),"..","test_screen.fits"))
wind_data = fits.open(fits_path)[0].data
for ts in range(1,ntime):
    IDL(".r edgemask")
    IDL("sig = readfits('{}',tmphead)".format(fits_path))
    IDL("previous = sig[*,*,{:d}]".format(ts-1))
    IDL("pprev = ptr_new(previous)")
    IDL("current = sig[*,*,{:d}]".format(ts))
    IDL("pcurr = ptr_new(current)")
    IDL.n = wind_data.shape[2]
    IDL("apa = fltarr{} + 1.0".format(shape))
    IDL("papa = ptr_new(apa)")
    IDL("a = edgemask(apa,apainner)")
    IDL("papai = ptr_new(apainner)")
    IDL.wind = wind
    # log.info("Comparing Gradients")
    IDL("grad = convol(depiston(current,apa),transpose([-0.5,0.0,0.5])) * apa")
    IDL_grad = IDL.grad
    kernel = np.zeros((3,3))
    kernel[1] = np.array([-0.5,0.0,0.5])
    # print(kernel)
    grad = scipy.signal.fftconvolve(wind_data[1],kernel.T,mode='same') * -1
    grad[0,:] = 0.0
    grad[-1,:] = 0.0
    log.info("Diff: \n{!s}".format(IDL_grad - grad))
    log.info("IDL Estimating Wind")
    IDL("ew = estimate_wind_gn(pcurr,pprev,n,papa,papai,wind,1)")
    aloc_inner = IDL.a
    IDL_wind_vec = IDL.ew
    log.info("Python Estimating Wind")
    wind_vec = estimate_wind_gn(wind_data[ts],wind_data[ts-1],wind=wind,aloc_inner=aloc_inner,IDLMode=True)
    log.info("IDL Wind Vector = [{:6.2f},{:6.2f}]".format(IDL_wind_vec[0,0],IDL_wind_vec[1,0]))
    log.info("Python Wind Vector = [{:6.2f},{:6.2f}]".format(wind_vec[0],wind_vec[1]))
IDL.close()
