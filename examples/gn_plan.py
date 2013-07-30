#!/usr/bin/env python
# 
#  gn_plan.py
#  aopy
#  
#  Created by Jaberwocky on 2013-05-10.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np
import os, os.path

import pidly

from aopy.atmosphere import wind
from wcao.estimators.gaussnewton import GaussNewtonEstimator
from wcao.data.case import WCAOCase
from pyshell.loggers import getSimpleLogger
from pyshell.util import ipydb

ipydb()
log = getSimpleLogger(__name__)

log.status("Loading Data")
Data = WCAOCase("Keck","sim_x25_y0",(WCAOCase.__module__,'telemetry.yml'))
Plan = GaussNewtonEstimator(iterations=100,order=1).setup(Data)
log.status("Estimating Phase")
Plan.estimate()
Plan.finish()
log.status("Plotting")
import matplotlib.pyplot as plt
fig = plt.figure()
Data.results["GN"].threepanelts(fig,smooth=dict(window=100,mode='flat'))
fig.savefig("Timeseries.pdf",dpi=600)
fig = plt.figure()
ax = fig.add_subplot(111)
Data.results["GN"].map(ax,smooth=dict(window=1000,mode='flat'),size=40,bins=101)
fig.savefig("Map.pdf")
log.status("Done")
