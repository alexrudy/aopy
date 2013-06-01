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
from wcao.data.core import WCAOCase
from pyshell.loggers import getSimpleLogger
from pyshell.util import ipydb

ipydb()

import scipy.fftpack

Data = WCAOCase("Keck","20070730_2",(WCAOCase.__module__,'telemetry.yml'))
Plan = FourierModeEstimator().setup(Data)
Data.telemetry.save_fmode()
Plan._periodogram()
Plan._periodogram_to_phase()
Plan._split_atmosphere_and_noise()
Plan._save_periodogram("periodogram.fits",clobber=True)

if __name__ == '__main__':
    import matplotlib.pyplot as plt
    PG = FMTSVisualizer(Plan)
    fig = plt.figure()
    ax = fig.add_subplot(1,1,1)
    PG.show_psd(ax,4,4,maxhz=500)
    plt.show()
