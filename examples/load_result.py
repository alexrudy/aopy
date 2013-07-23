#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  load_result.py
#  aopy
#  
#  Created by Jaberwocky on 2013-07-15.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)


import os, os.path

import numpy as np

from wcao.data.case import WCAOCase
from wcao.data.fmtsmap import WCAOFMTSMap
from pyshell.loggers import getSimpleLogger, configure_logging
from pyshell.util import ipydb
import pyshell


ipydb()

import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages

configure_logging(pyshell.PYSHELL_LOGGING)

Data = WCAOCase("Keck","20070730_2",(WCAOCase.__module__,'telemetry.yml'))
Data.addresult(None,WCAOFMTSMap,"FT")
Data.results["FT"].load()