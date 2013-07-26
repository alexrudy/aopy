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

Data = WCAOCase("GeMS","11360204434_pol_wfs1",configuration="wcao.yml")
Plan = FourierModeEstimator().setup(Data)
Plan.estimate()
Plan.finish()

print(Data)
Data.results["FT"].make_pdf()
fig = plt.figure(figsize=(8,6))
ax = fig.add_subplot(1,1,1)
Data.results["FT"].show_peak_fit(ax,5,15,maxhz=30)
ax.set_ylim(1e-3,10)
fig.savefig(Data.results["FT"].figname("pdf","K5L15"))
Data.results["FT"].save(clobber=True)
Data.results["FT"].save(single=False,clobber=True)

