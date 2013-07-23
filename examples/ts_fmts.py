#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  ts_fmts.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-07-23.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

from wcao.data.core import WCAOCase
from wcao.data.windmap import WCAOMap
from pyshell.util import ipydb
import pyshell
ipydb()



Data = WCAOCase("GeMS","11109092452_pol_wfs2",configuration="telemetry.yml")
dfiles = [ Data.telemetry.filepath("proc","{:d}_fwmap").format(i) for i in range(11) ]

for i,filepath in enumerate(dfiles):
    Data.results[i] = WCAOMap(Data,None,'FT')
    Data.results[i]._load_IDL_format_fits(filepath)
    
