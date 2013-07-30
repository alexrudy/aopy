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

from wcao.estimators.fmts import FourierModeEstimator,FMTSVisualizer
from wcao.data.case import WCAOCase
from pyshell.loggers import getSimpleLogger, configure_logging
from pyshell.util import ipydb
import pyshell

configure_logging(pyshell.PYSHELL_LOGGING_STREAM_ALL)

ipydb()

import scipy.fftpack

Data = WCAOCase("Keck","20070730_2",(WCAOCase.__module__,'telemetry.yml'))
Data.telemetry.load_fmode()
Plan = FourierModeEstimator().setup(Data)
Plan._load_periodogram("periodogram.fits")
Plan._read_peaks_from_table("peaks.fits")
Plan._fit_peaks_to_metric()
Plan._find_layers_in_watershed()
if __name__ == '__main__':
    Plot = FMTSVisualizer(Plan)
    import matplotlib.pyplot as plt
    fig = plt.figure()
    ax = fig.add_subplot(1,1,1)
    Plot.show_metric(ax)
    fig = plt.figure()
    Plot.show_fit(fig)
    fig.savefig("Layers.pdf")
    plt.show()

