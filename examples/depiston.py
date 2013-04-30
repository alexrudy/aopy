#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  depiston.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-26.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division, print_function)

import numpy as np
import numpy.random
import pidly
import os.path
from aopy.util.math import depiston

from pyshell import loggers

log = loggers.getSimpleLogger(__name__,loggers.INFO)

log.info("Setting up phase!")

phase = np.random.rand(10,10)
aloc = np.ones((10,10))

log.debug("Phase: {}".format(phase))

dp_phase = depiston(phase,aloc)

log.debug("De-Pistoned Phase: {}".format(dp_phase))

log.info("Change: {}".format(np.mean(dp_phase - phase)))

log.info("Launching IDL...")
IDL = pidly.IDL()
IDL('!PATH=!PATH+":"+expand_path("+~/Development/IDL/don_pro")')
luke_path = os.path.normpath(os.path.join(os.path.dirname(__file__),"..","IDL"))
IDL('!PATH=!PATH+":"+expand_path("+{:s}")'.format(luke_path))
IDL.phase = phase
IDL("apa = fltarr(10,10) + 1.0")
IDL("dp_phase = depiston(phase,apa)")
dp_phase_IDL = IDL.dp_phase
log.debug("De-Pistoned IDL Phase: {}".format(dp_phase_IDL))

log.info("Change (IDL): {}".format(np.mean(dp_phase_IDL - phase)))

