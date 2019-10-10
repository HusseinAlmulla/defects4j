#!/bin/bash

projects=$1
faults=`cat $2 | sed 's/,/ /g'`
trials=$3
budgets=$4
criteria=`cat $5 | sed 's/,/ /g'`
project_dir=$6"/defects4j/framework/projects"
all_classes=0

# Pre-configured
exp_dir=`pwd`
result_dir=$exp_dir"/results"
working_dir="/tmp"

mkdir $result_dir

# For each project
for project in $projects; do
	echo "------------------------"
	echo "-----Project "$project
	# For each fault
	for fault in $faults; do
		echo "-----Fault #"$fault
		# For each trial
		for (( trial=1; trial <= $trials ; trial++ )); do
			echo "-----Trial #"$trial
			# For each search budget
			for budget in $budgets; do
				echo "----Search Budget: "$budget	
				# Generate EvoSuite tests
				for criterion in $criteria; do
					crinosc=`echo $criterion | sed 's/:/-/g'`
					mkdir $working_dir"/"$project"_"$fault

                                        if [ -a $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial"/"$project"-"$fault"f-evosuite-"$crinosc"."$trial".tar.bz2" ]; then
						echo "Suite already exists."
					else
						echo "-----Generating EvoSuite tests for "$criterion
						# Add configuration ID to evo config
						cp ../util/evo.config evo.config.backup
                       		        	echo "-Dconfiguration_id=evosuite-"$crinosc"-"$trial >> ../util/evo.config

						if [ $all_classes -eq 1 ]; then
							echo "(all classes)"
							perl ../bin/run_evosuite.pl -p $project -v $fault"f" -n $trial -o $result_dir"/suites/"$project"_"$fault"/"$budget -c $criterion -b $budget -t $working_dir"/"$project"_"$fault -a 450 -C
						else
							echo "(only patched classes)"
							echo "../bin/run_evosuite.pl -p $project -v $fault"f" -n $trial -o $result_dir"/suites/"$project"_"$fault"/"$budget -c $criterion -b $budget -t $working_dir"/"$project"_"$fault -a 450"
							perl ../bin/run_evosuite.pl -p $project -v $fault"f" -n $trial -o $result_dir"/suites/"$project"_"$fault"/"$budget -c $criterion -b $budget -t $working_dir"/"$project"_"$fault -a 450
						fi

						mv evo.config.backup ../util/evo.config
						cat evosuite-report/statistics.csv >> $result_dir"/suites/"$project"_"$fault"/"$budget"/generation-statistics.csv"
						rm -rf evosuite-report

                                	      	# Detect and remove non-compiling tests
						echo "-----Checking to see if suite needs fixed"
						perl ../util/fix_test_suite.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial -t $working_dir"/"$project"_"$fault

       	                # Generate coverage reports
                        echo "-----Generating coverage reports"

						if [ $all_classes -eq 1 ]; then
							echo "(all loaded classes)"
	                              perl ../bin/run_evosuite_coverage.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial -o $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial -f "**/*Test.java" -t $working_dir"/"$project"_"$fault -c default -A
						else
							echo "(only patched classes)"
  						        perl ../bin/run_evosuite_coverage.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial -o $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial -f "**/*Test.java" -t $working_dir"/"$project"_"$fault -c default
						fi

						# Measure fault detection
						echo "----Measuring fault detection"
				     	   	perl ../bin/run_bug_detection.pl -p $project -d $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc"/"$trial -o $result_dir"/suites/"$project"_"$fault"/"$budget"/"$project"/evosuite-"$crinosc -f "**/*Test.java" -t $working_dir"/"$project"_"$fault

						
						rm -rf $working_dir"/"$project"_"$fault 
					fi	
				done
			done
		done
		tar cvzf $project"_"$fault"_rl.tgz" $result_dir"/suites/"$project"_"$fault"/"	
	done
done
