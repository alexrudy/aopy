#!/usr/bin/env python
# 
#  periodogram.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-15.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import os, os.path

import numpy as np

from wcao.estimators.fmts import FourierModeEstimator
from wcao.data.case import WCAOCase
from pyshell.loggers import getSimpleLogger, configure_logging
from pyshell.util import ipydb
import pyshell

# configure_logging(pyshell.PYSHELL_LOGGING)

ipydb()

import matplotlib.pyplot as plt

Data = WCAOCase("keck_simulated","sim_1",(WCAOCase.__module__,'telemetry.yml'))
Plan = FourierModeEstimator().setup(Data)
Plan.estimate()
Plan.finish()
fig = plt.figure()
ax = fig.add_subplot(1,1,1)
Data.results["FT"].show_metric(ax)

fig = plt.figure()
ax = fig.add_subplot(1,1,1)
Data.results["FT"].show_peak_fit(ax,0,12)
fig = plt.figure()
ax = fig.add_subplot(1,1,1)
Data.results["FT"].show_mask(ax)
fig = plt.figure()
Data.results["FT"].show_fit(fig)
fig = plt.figure()
ax = fig.add_subplot(1,1,1)
Data.results["FT"].show_peaks(ax)

plt.show()

