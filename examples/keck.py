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


ipydb()

import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages

Data = WCAOCase("Keck","20070730_2")
Plan = FourierModeEstimator().setup(Data)
Plan.estimate()
Plan.finish()

print(Data)

Data.results["FT"].make_pdf()

Data.results["FT"].save(clobber=True)
Data.results["FT"].save(single=False,clobber=True)