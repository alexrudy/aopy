#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  ts_fmts.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-07-23.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np

from wcao.data.case import WCAOCase
from wcao.data.windmap import WCAOMap
from wcao.data.timeseries import WCAOTimeseries
from pyshell.util import ipydb
import pyshell

ipydb()

Data = WCAOCase("keck_simulated","sim_1",configuration="wcao.yml")
Data.telemetry.phase # Force load the phase from the processed raw data for Keck

dfiles = [ Data.telemetry.filepath("proc","{:d}_fwmap").format(i) for i in range(13) ]

del dfiles[1]

for i,filepath in enumerate(dfiles):
    Data.results[i] = WCAOMap(Data,None,'FT')
    Data.results[i]._load_IDL_format_fits(filepath)
    

    
sizes = [ len(result.layers) for result in Data.results.values() ]
tsdata = np.zeros((len(Data.results),max(sizes),2),dtype=float)
for i,result in enumerate(Data.results.values()):
    for j,layer in enumerate(result.layers):
        tsdata[i,j,0] = layer["vx"]
        tsdata[i,j,1] = layer["vy"]       
    for j in range(len(result.layers),max(sizes)):
        tsdata[i,j,0] = np.nan
        tsdata[i,j,1] = np.nan

Data.results["TS"] = WCAOTimeseries(Data, tsdata, "FS", timestep=(1.0/Data.rate * 2048))
np.savetxt(Data.results["TS"].figname("txt","Data"),Data.results["TS"].data[:,0,:])

Data.results["GN"] = WCAOTimeseries(Data, None, "GN", timestep=(1.0/Data.rate))
Data.results["GN"].load_IDL(Data.telemetry.filepath("proc","wind"))
Data.results["GN"].clip = slice(None,Data.results["GN"].ntime-3000)

mag = lambda data : np.sqrt(np.sum(data**2.0,axis=1))
# Statistics
print("FS: {mean:5.2f} ±{std:5.2f}".format(
    mean=np.mean(mag(Data.results["TS"].data[:,0,:])),
    std=np.std(mag(Data.results["TS"].data[:,0,:])),
))
print("GN: {mean:5.2f} ±{std:5.2f}".format(
    mean=np.mean(mag(Data.results["GN"].smoothed(1024,'flat')[100:,0,:])),
    std=np.std(mag(Data.results["GN"].smoothed(1024,'flat')[100:,0,:])),
))
# Figures

import matplotlib.pyplot as plt
fig = plt.gcf()
Data.results["GN"].threepanelts(fig,smooth=dict(window=1024,mode='flat'))
Data.results["TS"].threepanelts(fig,smooth=False)
fig.savefig(Data.results["TS"].figname("pdf","FS3p"))
ax = plt.figure(figsize=(10,4)).add_subplot(111)
Data.results["GN"].timeseries(ax,2,smooth=dict(window=1024,mode='flat'))
Data.results["TS"].timeseries(ax,2,smooth=False,marker='.')
ax.set_ylim(0,ax.get_ylim()[1])
ax.set_ylabel(r"Wind $(m/s)$")
ax.set_xlabel(r"Time $(s)$")
Data.results["TS"]._header(ax.figure)
ax.figure.savefig(Data.results["TS"].figname("pdf","MTS"),dpi=600)