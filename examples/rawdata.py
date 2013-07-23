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
from pyshell.loggers import getSimpleLogger
from pyshell.util import ipydb

ipydb()

import scipy.fftpack

Data = WCAOCase("Keck","20070730_2",(WCAOCase.__module__,'telemetry.yml'))
Data.telemetry.load_raw()
Data.telemetry.save_fmode()
Data.telemetry.save_phase()

