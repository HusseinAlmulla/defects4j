#!/bin/bash

echo "STRONGMUTATION"> cc1.csv

echo "42,39" > ff1.csv
python Run_experiement_with_linux.py Lang ff1.csv 10 "120" cc1.csv $HOME "EVSF_DSGSARSA_EPSG"

echo "8,19" > ff1.csv
python Run_experiement_with_linux.py Chart ff1.csv 10 "120" cc1.csv $HOME "EVSF_DSGSARSA_EPSG"

echo "8,12" > ff1.csv
python Run_experiement_with_linux.py Time ff1.csv 10 "120" cc1.csv $HOME "EVSF_DSGSARSA_EPSG"

echo "60,70" > ff1.csv
python Run_experiement_with_linux.py Math ff1.csv 10 "120" cc1.csv $HOME "EVSF_DSGSARSA_EPSG"

echo "22,54" > ff1.csv
python Run_experiement_with_linux.py Closure ff1.csv 10 "120" cc1.csv $HOME "EVSF_DSGSARSA_EPSG"


