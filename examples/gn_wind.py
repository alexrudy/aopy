#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  gn_wind.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-18.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np
import os, os.path

import pidly

from aopy.atmosphere import wind
from wcao.gaussnewton import estimate_wind_gn, GaussNewtonEstimator

from astropy.utils.console import ProgressBar
from astropy.io import fits
from pyshell.loggers import getSimpleLogger
from pyshell.util import ipydb
ipydb()


log = getSimpleLogger(__name__)
idllog = getSimpleLogger("IDL")

shape = (30,30)
du = 10/30
r0 = 0.30
ntime = 200
wfrac = 1

log.status("Setting up screen")
Screen = wind.ManyLayerScreen(shape,r0,seed=10,du=du,vel=[[0,0],[0,2]],tmax=int(wfrac * ntime)+1).setup()
log.info("Maximum step before wrap is {:d}".format(int(wfrac * ntime)+1))
screen = np.zeros((ntime,)+shape)
log.status("Writing screen to array")
with ProgressBar(ntime) as pbar:
    for i in range(ntime):
        screen[i,...] = Screen.get_screen(i)
        pbar.update(i)
fits.writeto("test_screen.fits",screen,clobber=True)
log.status("Wrote screen to file")
results = np.zeros((ntime,2))
IDLM_results = np.zeros((ntime,2))
IDL_results = np.zeros((ntime,2))
Plan_results = np.zeros((3,ntime,2))
wind = None
idl_wind = None

idllog.status("Launching IDL...")
IDL = pidly.IDL()
IDL('!PATH=!PATH+":"+expand_path("+~/Development/Astronomy/IDL/don_pro")')
luke_path = os.path.normpath(os.path.join(os.path.dirname(__file__),"..","IDL"))
IDL('!PATH=!PATH+":"+expand_path("+{:s}")'.format(luke_path))

idllog.status("Setting Up Environment...")
fits_path = os.path.normpath(os.path.join(os.path.dirname(__file__),"..","test_screen.fits"))
IDL(".r edgemask")
IDL("sig = readfits('{}',tmphead)".format(fits_path))

IDL.n = shape[0]
IDL("apa = fltarr{} + 1.0".format(shape))
IDL("papa = ptr_new(apa)")
IDL("a = edgemask(apa,apainner)")
IDL("papai = ptr_new(apainner)")
IDL("wind = [0,0]")
IDL("ewind = fltarr(2)")
IDL(".r estimate_wind_gn")
IDL(".r depiston")

log.status("Initializing Planned GN")
plan_normal = GaussNewtonEstimator().setup(np.ones(shape))
plan_fft = GaussNewtonEstimator(fft=True).setup(np.ones(shape))
plan_idl = GaussNewtonEstimator(idl=True).setup(np.ones(shape))
log.status("Estimating wind")
with ProgressBar(ntime) as pbar:
    for i in range(1,ntime):
        IDL("previous = sig[*,*,{:d}]".format(i-1))
        IDL("pprev = ptr_new(previous)")
        IDL("current = sig[*,*,{:d}]".format(i))
        IDL("pcurr = ptr_new(current)")
        IDL("ewind = estimate_wind_gn(pcurr,pprev,n,papa,papai,wind,1)")
        # IDL("wind[0:1] = ewind[0:1]")
        IDL("ptr_free,pprev")
        IDL("ptr_free,pcurr")
        IDL_wind_vec = IDL.ewind
        IDLM_results[i,:] = IDL_wind_vec[:,0][::-1]
        wind = estimate_wind_gn(screen[i,...],screen[i-1,...],max_it=10,wind=wind)
        idl_wind = estimate_wind_gn(screen[i,...],screen[i-1,...],max_it=10,wind=idl_wind,IDLMode=True,fft=True)
        IDL_results[i,:] = idl_wind[::-1]
        results[i,:] = wind[::-1]
        IDL.wind = IDL_wind_vec[:,0]
        for p,plan in enumerate([plan_normal,plan_fft,plan_idl]):
            Plan_results[p,i,...] = plan.estimate(screen[i,...],screen[i-1,...])[0,::-1]
        pbar.update(i)

msg = ["Wind Average:",
"Python    : [{:5.2f},{:5.2f}]".format(*np.mean(results,axis=0)),
"IDLport   : [{:5.2f},{:5.2f}]".format(*np.mean(IDL_results,axis=0)),
"pIDLy     : [{:5.2f},{:5.2f}]".format(*np.mean(IDLM_results,axis=0)),
"plan_norm : [{:5.2f},{:5.2f}]".format(*np.mean(Plan_results[0,...],axis=0))
]
log.info("\n".join(msg))

# log.info("Wind at step (0,30,300) = [{:.2f},{:.2f}],[{:.2f},{:.2f}],[{:.2f},{:.2f}]".format(*results[[0,30,300],:].flatten()))
log.status("Plotting")
import matplotlib.pyplot as plt

fig = plt.figure()
ax1 = fig.add_subplot(3,1,1)
ax2 = fig.add_subplot(3,1,2)
ax3 = fig.add_subplot(3,1,3)
time = np.arange(ntime)[1:]
ax1.set_title("$x$ wind")
ax1.plot(time,results[1:,0],'g.')
ax1.plot(time,IDL_results[1:,0],'b.')
ax1.plot(time,IDLM_results[1:,0],'c.')
for p in range(Plan_results.shape[0]):
    ax1.plot(time,Plan_results[p,1:,0],'.')
ax2.set_title("$y$ wind")
ax2.plot(time,results[1:,1],'g.')
ax2.plot(time,IDL_results[1:,1],'b.')
ax2.plot(time,IDLM_results[1:,1],'c.')
for p in range(Plan_results.shape[0]):
    ax2.plot(time,Plan_results[p,1:,1],'.')
ax3.set_title("$|w|$ wind")
ax3.plot(time,np.sqrt(np.sum(np.power(results,2)[1:],axis=1)),'g.')
ax3.plot(time,np.sqrt(np.sum(np.power(IDL_results,2)[1:],axis=1)),'b.')
ax3.plot(time,np.sqrt(np.sum(np.power(IDLM_results,2)[1:],axis=1)),'c.')

for axes in fig.axes:
    axes.set_xlim(0,ntime)

fig2 = plt.figure()
ax1 = fig2.add_subplot(2,1,1)
diff = IDLM_results[1:]-IDL_results[1:]
ax1.plot(time,diff[:,0],'b.')
ax1.set_title("$\Delta x$ wind")

ax2 = fig2.add_subplot(2,1,2)
ax2.set_title("$\Delta y$ wind")
ax2.plot(time,diff[:,1],'b.')

for axes in fig2.axes:
    axes.set_xlim(0,ntime)

plt.show()
