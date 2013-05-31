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
from pyshell.loggers import getSimpleLogger, configure_logging
from pyshell.util import ipydb
import pyshell

configure_logging(pyshell.PYSHELL_LOGGING)

ipydb()

import scipy.fftpack

Data = WCAOCase("Keck","20070730_2",(WCAOCase.__module__,'telemetry.yml'))
Data.telemetry.load_fmode()
Plan = FourierModeEstimator().setup(Data)
Plan._load_periodogram("periodogram.fits")
Plan._create_peak_template()
Plan._find_and_fit_peaks()
Plan._save_peaks_to_table("peaks.fits",clobber=True)
if __name__ == '__main__':
    Plot = Periodogram(Plan)
    import matplotlib.pyplot as plt
    fig = plt.figure()
    ax = fig.add_subplot(1,1,1)
    Plot.show_peak_fit(ax,4,4)
    fig = plt.figure()
    ax = fig.add_subplot(1,1,1)
    Plot.show_template(ax,4,4)
    plt.show()

