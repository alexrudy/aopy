#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  try_screengen.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-12.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 

import aopy.atmosphere.atmosphere as screengen
import numpy as np
args = {
    'n': 300,
    'm': 300,
    'r0': 4,
    'du': 1,
    'seed':5,
}
ntrial = int(1e4)
import pidly
import time
times = {}
print("Launching IDL...")
IDL = pidly.IDL()
IDL('!PATH=!PATH+":"+expand_path("+~/Development/IDL/don_pro")')
print("Generating Filter")
times["IDL_f"] = -time.clock()
for i in range(ntrial):
    IDL('f = screengen({n:d},{m:d},{r0:f},{du:f})'.format(**args))
times["IDL_f"] += time.clock()
f_don = IDL.f
times["PY_f"] = -time.clock()
for i in range(ntrial):
    f_alex, shf = screengen.generate_filter((args['n'],args['m']),args['r0'],args['du'])
times["PY_f"] += time.clock()
print("Checking Filter Functions for IDL vs Python")
f_result = np.allclose(f_don,f_alex)
print("Filters match=%s" % f_result)
print("""
Timing Information
------------------
IDL: {IDL_f:.2g} s
PY:  {PY_f:.2g} s
""".format(**times))

print("Making Screen")
IDL('noise = randomn({seed:d},{n:d},{m:d})'.format(**args))
times["IDL_s"] = -time.clock()
for i in range(ntrial):
    IDL('s = screengen(f,{seed:d})'.format(**args))
times["IDL_s"] += time.clock()

s_don = IDL.s
noise = IDL.noise
times["PY_n"] = -time.clock()
for i in range(ntrial):
    s_alex = screengen.generate_screen_with_noise(f_alex,noise)
times["PY_n"] += time.clock()
times["PY_s"] = -time.clock()
for i in range(ntrial):
    screengen.generate_screen(f_alex,args["seed"])
times["PY_s"] += time.clock()
s_result=np.allclose(s_don,s_alex,atol=1e-5)
print("Screens match=%s" % s_result)
print("""
Timing Information
------------------
IDL: {IDL_s:.2g} s
PY:  {PY_s:.2g} s
PY_n: {PY_n:.2g} s
""".format(**times))


IDL.close()
