#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  make_wind.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-18.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

from pyshell.loggers import getSimpleLogger
import numpy as np

import astropy.io.fits as pf
from aopy.atmosphere import wind

log = getSimpleLogger(level=10)

shape = (10,10)
du = 10/30
r0 = 0.30
ntime = 200

Screen = wind.ManyLayerScreen(shape,r0,du=du,vel=[0,1]).setup()

log.debug("Screen Velocity {!s}".format(Screen.velocity))

screen = np.zeros((ntime,)+shape)
for i in range(ntime):
    screen[i,...] = Screen.get_screen(i)

pf.writeto("test_screen.fits",screen,clobber=True)

