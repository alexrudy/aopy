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
from wcao.data.core import WCAOCase
from astropy.utils.console import ProgressBar
from astropy.io import fits
from pyshell.config import StructuredConfiguration
from pyshell.loggers import getSimpleLogger
from pyshell.util import ipydb

ipydb()
log = getSimpleLogger(__name__)

log.status("Loading Data")
Data = WCAOCase("Keck","simulated",(WCAOCase.__module__,'telemetry.yml'))
Plan = GaussNewtonEstimator(iterations=10).setup(Data)
log.status("Estimating Phase")
Plan.estimate()
Plan.finish()
log.status("Plotting")
import matplotlib.pyplot as plt
fig = plt.figure()
Data.results["GN"].threepanelts(fig)
fig.savefig("Timeseries.pdf",dpi=600)
fig = plt.figure()
ax = fig.add_subplot(111)
Data.results["GN"].map(ax,size=40,bins=101)
fig.savefig("Map.pdf")
log.status("Done")
