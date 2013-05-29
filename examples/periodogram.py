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

from wcao.estimators.fmts import FourierModeEstimator,Periodogram
from wcao.data.core import WCAOCase
from pyshell.loggers import getSimpleLogger
from pyshell.util import ipydb

ipydb()

import scipy.fftpack

Data = WCAOCase("Keck","20070730_2",(WCAOCase.__module__,'telemetry.yml'))
Data.telemetry.load_fmode()
Plan = FourierModeEstimator().setup(Data)
Plan._periodogram()
Plan._periodogram_to_phase()
Plan._split_atmosphere_and_noise()
Plan._save_periodogram("periodogram.fits",clobber=True)
import matplotlib.pyplot as plt
PG = Periodogram(Plan)
compare = scipy.fftpack.fftshift(np.loadtxt("mpd04.txt"))
fig = plt.figure()
ax = fig.add_subplot(1,1,1)
ax.plot(Plan.hz,compare)
PG.show_psd(ax,4,0,maxhz=300)
plt.show()
