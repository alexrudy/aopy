#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  try_screengen.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-12.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 

import aopy.atmosphere.screen as screengen
import numpy as np
import pidly
import time

try:
    import pyshell
    import pyshell.util

    pyshell.util.ipydb()
    log = pyshell.getSimpleLogger("__main__")
except ImportError:
    import logging
    log = logging.getLogger(__name__)
    logging.basicConfig()


def test_array(a,b,name=""):
    """docstring for test_array"""
    result = np.allclose(a,b,rtol=1e-4)
    if result:
        log.info("{name:s} match={result!s}".format(name=name,result=result))
    else:
        log.error("{name:s} match={result!s}".format(name=name,result=result))
        print("A={!r}".format(a))
        print("B={!r}".format(b))
    return result

# Screengen Arguments
args = {
    'n': 10,
    'm': 10,
    'r0': 4,
    'du': 1,
    'seed':5,
    'nsh':8,
}
# Number fo timing trials
ntrial = int(1)
# Path to Don's IDL Libraries
DON_PATH = "./IDL/screengen"
idl_output = True

times = {}
log.status("Launching IDL...")
IDL = pidly.IDL()
IDL('!PATH=expand_path("<IDL_default>")+":"+expand_path("+{:s}")'.format(DON_PATH))
# IDL('which,"screegen"')
log.status("\nScreengen\n===========================")
log.info("Generating Filter")
times["IDL_f"] = -time.clock()
for i in range(ntrial):
    IDL('f = screengen({n:d},{m:d},{r0:f},{du:f})'.format(**args),print_output=idl_output)
times["IDL_f"] += time.clock()
f_don = IDL.f
times["PY_f"] = -time.clock()
for i in range(ntrial):
    f_alex, shf = screengen._generate_filter((args['n'],args['m']),args['r0'],args['du'])
times["PY_f"] += time.clock()
log.status("Checking Filter Functions for IDL vs Python")
f_result = test_array(f_don,f_alex,"Filters")
log.info("""
Timing Information
------------------
pIDLy:  {IDL_f:.2g} s
python:  {PY_f:.2g} s
""".format(**times))

log.status("Making Screen")
IDL.ex('noise = randomn({seed:d},{n:d},{m:d})'.format(**args),print_output=idl_output)
times["IDL_s"] = -time.clock()
for i in range(ntrial):
    IDL('s = screengen(f,{seed:d})'.format(**args),print_output=idl_output)
times["IDL_s"] += time.clock()

s_don = IDL.s
noise = IDL.noise
times["PY_n"] = -time.clock()
for i in range(ntrial):
    s_alex = screengen._generate_screen_with_noise(f_alex,noise,du=args["du"])
times["PY_n"] += time.clock()
times["PY_s"] = -time.clock()
for i in range(ntrial):
    screengen._generate_screen(f_alex,args["seed"])
times["PY_s"] += time.clock()
log.status("Checking Screen Functions for IDL vs Python")
s_result=test_array(s_don,s_alex,"Screens")
log.info("""
Timing Information
------------------------------
pIDLy:             {IDL_s:.2g} s
python:            {PY_s:.2g} s
python (no noise): {PY_n:.2g} s
""".format(**times))

log.info("")
log.status("\nScreengen with SubHarmonics\n===========================")
log.status("Generating Filter")
times["IDL_fh"] = -time.clock()
for i in range(ntrial):
    IDL('f = screengen({n:d},{m:d},{r0:f},{du:f},{nsh:d},shf)'.format(**args))
times["IDL_fh"] += time.clock()
f_don = IDL.f
shf_don = IDL.shf
times["PY_fh"] = -time.clock()
for i in range(ntrial):
    f_alex, shf_alex = screengen._generate_filter((args['n'],args['m']),r0=args['r0'],du=args['du'],nsh=args['nsh'])
times["PY_fh"] += time.clock()
log.status("Checking Filter Functions for IDL vs Python")
f_result = test_array(f_don,f_alex,"Filters with Subharmonics")
shf_result = test_array(shf_don,shf_alex.T,"Subharmonic Filters")
log.info("""
Timing Information
------------------
pIDLy:  {IDL_fh:.2g} s
python:  {PY_fh:.2g} s
""".format(**times))

log.status("Making Screen")
IDL.ex('noise = randomn({seed:d},{n:d},{m:d})'.format(**args),print_output=idl_output)
IDL.ex('shf_noise = (randomn({seed:d},4) + complex(0,1)*randomn({seed:d},4))/sqrt(2.)'.format(**args))
IDL.ex('shf_noise_a = real(shf_noise)'.format(**args),print_output=idl_output)
IDL.ex('shf_noise_b = imaginary(shf_noise)'.format(**args),print_output=idl_output)
times["IDL_s"] = -time.clock()
for i in range(ntrial):
    IDL('s = screengen_fn(f,{seed:d},shf,{du:f},shf_noise)'.format(**args),print_output=idl_output)
times["IDL_s"] += time.clock()

sh_don = IDL.s
noise = IDL.noise
sh_noise_a = IDL.shf_noise_a
sh_noise_b = IDL.shf_noise_b
sh_noise = (sh_noise_a + 1.0j * sh_noise_b)
times["PY_n"] = -time.clock()
for i in range(ntrial):
    sh_alex = screengen._generate_screen_with_noise(f_alex,noise,shf_alex,sh_noise,args["du"])
times["PY_n"] += time.clock()
times["PY_s"] = -time.clock()
for i in range(ntrial):
    screengen._generate_screen(f_alex,args["seed"])
times["PY_s"] += time.clock()
log.status("Checking Screen Functions for IDL vs Python")
s_result=test_array(sh_don,sh_alex,"Screens with Subharmonics")
log.info("""
Timing Information
------------------------------
pIDLy:             {IDL_s:.2g} s
python:            {PY_s:.2g} s
python (no noise): {PY_n:.2g} s
""".format(**times))

IDL.close()
