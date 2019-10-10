#!/bin/bash

echo "LINE:BRANCH:EXCEPTION:WEAKMUTATION:OUTPUT:METHOD:METHODNOEXCEPTION:CBRANCH"> cc1.csv

echo "60" > ff1.csv
./generate_tests_rl.sh Math ff1.csv 10 "600" cc1.csv $HOME

echo "70" > ff1.csv
./generate_tests_rl.sh Math ff1.csv 10 "600" cc1.csv $HOME

echo "22" > ff1.csv
./generate_tests_rl.sh Closure ff1.csv 10 "600" cc1.csv $HOME

echo "54" > ff1.csv
./generate_tests_rl.sh Closure ff1.csv 10 "600" cc1.csv $HOME

echo "42" > ff1.csv
./generate_tests_rl.sh Lang ff1.csv 10 "600" cc1.csv $HOME

