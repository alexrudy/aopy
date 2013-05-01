# -*- coding: utf-8 -*-
# 
#  setup.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-04-12.
#  Copyright 2012 Alexander Rudy. All rights reserved.
# 

from distribute_setup import use_setuptools
use_setuptools()
from setuptools import setup, find_packages

from aopy import version

setup(
    name = "aopy",
    version = version,
    packages = find_packages(exclude=['']),
    package_data = {'aopy': ['aopy/data/*'],
    'wcao' : ['wcao/estimators/pidly/idl/*.pro']},
    install_requires = ['distribute','numpy>=1.7','scipy>=0.11'],
    author = "Alexander Rudy",
    author_email = "alex.rudy@gmail.com",
    entry_points = {
        'console_scripts' : [
            'WCAO = wcao.analysis.core:WCAOPipeline.script'
        ]
    }
    )