# -*- coding: utf-8 -*-
"""
Created on Tue Oct  1 18:37:05 2019

@author: Hussein
"""

# input like

#  python Run_experiement_with_linux.py project fault.csv trial "budget" criteria.csv $HOME "approach"


import re
import os
import csv
import sys
from glob import glob
import shutil
import mysql.connector
from mysql.connector import Error



projects=sys.argv[1].split(",")
file1  = open(sys.argv[2], "r") 
faults = file1.read().split(",")
trials=sys.argv[3]
budgets=sys.argv[4].split(",")
file2  = open(sys.argv[5], "r") 
criteria = file2.read().split(",")
project_dir=sys.argv[6]+"/defects4j/framework/projects"
approach=sys.argv[7]
all_classes=0
exp_dir=os.getcwd()
result_dir=exp_dir+"/results"
working_dir="/tmp"



outfile  = open('./ReasultsInfo.txt', "a")
outfile.write("Approach, Project,Fault,Trial,Criteria,Num_Second,Num_Generation,Num_Tests,Test_Length,SM_Coverage,Faults_Detected,Num_Failing-Tests \n")
outfile.close()


def adding_to_File(TestInfo, numtrial):
	outfile  = open('./ReasultsInfo.txt', "a")
	
	for trial in range(1, int(numtrial)+1):
		outfile.write("{},{},{},{},{},{},{},{},{},{},{},{}".format(TestInfo[trial][0], TestInfo[trial][1],TestInfo[trial][2], TestInfo[trial][3], TestInfo[trial][4], TestInfo[trial][5], TestInfo[trial][6], TestInfo[trial][7], TestInfo[trial][8], TestInfo[trial][9], TestInfo[trial][10], TestInfo[trial][11]))
	outfile.close()




def adding_to_DB(TestInfo, numtrial):
	print("Connecting to MySQL Server DB")
	
	values = "('{}','{}','{}','{}','{}','{}','{}','{}','{}','{}','{}','{}')".format(TestInfo[1][0], TestInfo[1][1],TestInfo[1][2], TestInfo[1][3], TestInfo[1][4], TestInfo[1][5], TestInfo[1][6], TestInfo[1][7], TestInfo[1][8], TestInfo[1][9], TestInfo[1][10], TestInfo[1][11])
	
	for trial in range(2, int(numtrial)+1):
		values = values + "," + "('{}','{}','{}','{}','{}','{}','{}','{}','{}','{}','{}','{}')".format(TestInfo[trial][0], TestInfo[trial][1],TestInfo[trial][2], TestInfo[trial][3], TestInfo[trial][4], TestInfo[trial][5], TestInfo[trial][6], TestInfo[trial][7], TestInfo[trial][8], TestInfo[trial][9], TestInfo[trial][10], TestInfo[trial][11])
	
	
	columns = '(`Approach`,`Project`,`Faults`,`Trial`,`Criteria`,`Num_Second`,`Num_Generation`,`Num_Tests`,`Test_Length`, `SM_Coverage`, `Faults_Detected`, `Num_Failing_Tests`)'
	
	insert_cmd = 'INSERT INTO `expr_data_result`.`Data_results` {} VALUES {};'.format(columns, values)
	print(insert_cmd)
	try:
		connection = mysql.connector.connect(host='expdata.cimqzxtw4rae.us-east-1.rds.amazonaws.com',
						database='expr_data_result',
						user='admin',
						password='ExpRun2019AWS')

		if connection.is_connected():
			print("Connected ...")
			cursor=connection.cursor()
			
			print("Writing to the table ...")
			cursor.execute(insert_cmd)
			connection.commit()
			print("Done ...")
	except Error as e:
		print("Error ...")
		outfile  = open('./Error_log.txt', "a")
		outfile.write("	Error while connecting to MySQL {} for values\n\n".format(e, values))
		outfile.close()
	finally:
		if (connection.is_connected()):
			cursor.close()
			connection.close()
			print("MySQL connection is closed")	



def GetFailTestInfo(filePath):
# Getting the failing information from the file and store it in array.
	failInfo = ["NA","NA","NA","NA","NA","NA","NA","NA","NA","NA","NA"]
	with open(filePath, ) as csvfile:
		csvReader = csv.reader(csvfile, delimiter=',')
		next(csvReader)
		for row in csvReader:
			splitRow = ','.join(row).split(",")
			#[faultDetection,numOfFailing]
			failInfo[int(splitRow[3])] = [splitRow[4],splitRow[5]]
		return failInfo


def GetInfo(proj,fault,criteria,numtrial, budget):      
	TestsList = ["NA","NA","NA","NA","NA","NA","NA","NA","NA","NA","NA"]
	curPath = "{}/suites/{}_{}/{}".format(result_dir,project,fault,budget)
	print("Gethering results ................")
	for trial in range(1,int(numtrial)+1):
		fileName = "{}.{}f.{}.{}.log".format(proj,fault,criteria,trial)
		logFile = curPath + "/logs/" + fileName
		if (not(os.path.exists(logFile))):
			CoreRun(project,fault,trial,budget,crinosc, "get info")
			print("-----1st - Regenerating tests for {} fault {}".format(trial,fault))
		if (not(os.path.exists(logFile))):
			CoreRun(project,fault,trial,budget,crinosc, "get info")
			print("-----2nd - Regenerating tests for {} fault {}".format(trial,fault))
		if (os.path.exists(logFile)):
			file  = open(logFile, "r") 
			text = file.read()
			trial = int(trial)
			TestInfo = ["NA","NA","NA","NA","NA","NA"]
			TestInfo[0] = criteria
			genLine = re.findall('Search finished after [0-9]+s and [0-9]+ generations', text)
			if(genLine is not None):
				for item in genLine:
					tmp_genLine = str(item).split(" ")
					TestInfo[1] = tmp_genLine[3]
					TestInfo[2] = tmp_genLine[5]
					break

			testSizeLine = re.findall('Generated [0-9]+ tests with total length [0-9]+', text)
			if(testSizeLine is not None):
				for item in testSizeLine:
					tmp_testSizeLine = str(item).split(" ")
					TestInfo[3] = tmp_testSizeLine[1]
					TestInfo[4] = tmp_testSizeLine[6]
					break

			SMScore = re.findall('Resulting test suite\'s mutation score: [0-9]+\%', text)
			if(SMScore is not None):
				for item in SMScore:
					tmp_SMScore = str(item).split(":")
					TestInfo[5] = tmp_SMScore[1]
					break

			file.close()
			failingTestInfo = GetFailTestInfo("{}/{}/evosuite-{}/bug_detection".format(curPath,proj,criteria))
			if(failingTestInfo[trial] != "NA"):
				if(failingTestInfo[trial][0] == "Pass"):
					fault_detection = 0
				elif(failingTestInfo[trial][0] == "Fail"):
					fault_detection = 1
				else:
					fault_detection = "-"
				num_failing = failingTestInfo[trial][1]
			else:
				fault_detection = num_failing = "NA"
	
			criteria = TestInfo[0]
			num_sec = TestInfo[1].replace("s","")
			num_gen = TestInfo[2]
			test_size = TestInfo[3]
			test_len = TestInfo[4]
			sm_score = TestInfo[5].replace("%","").strip()
		
			TestsList[trial] = [approach, proj,fault, trial, criteria, num_sec, num_gen, test_size, test_len, sm_score, fault_detection, num_failing]
		else:
			print("file NOT exist")
			TestsList[trial] = [approach, proj,fault, trial, criteria, "NA", "NA", "NA", "NA", "NA", "NA", "NA"]
	
		
	adding_to_DB(TestsList, numtrial)
	adding_to_File(TestsList, numtrial)
	
###################

def CoreRun(project,fault,trial,budget,crinosc, txt):
	if (os.path.exists(working_dir+"/"+project+"_"+fault)):
		shutil.rmtree(working_dir+"/"+project+"_"+fault)
		os.mkdir(working_dir+"/"+project+"_"+fault)
	else:
		os.mkdir(working_dir+"/"+project+"_"+fault)

	filePath = "{}/suites/{}_{}/{}/{}/evosuite-{}/{}/{}-{}f-evosuite-{}.{}.tar.bz2".format(result_dir,project,fault,budget,project,crinosc,trial,project,fault,crinosc,trial)

	if (os.path.exists(filePath)):
		print("Suite already exists.")
	else:
		print("-----Generating EvoSuite tests for {}".format(crinosc))
		os.system('cp ../util/evo.config evo.config.backup')
		with open("../util/evo.config", "a") as evoConfig:
			evoConfig.write("-Dconfiguration_id=evosuite-{}-{}\n".format(crinosc, trial))
			evoConfig.close()
		if (all_classes == 1) :
			print("(all classes)")
			cmd1 = 'perl ../bin/run_evosuite.pl -p {} -v {}f -n {} -o {}/suites/{}_{}/{} -c {} -h {} -b {} -t {}/{}_{} -a 450 -C'.format(project,fault,trial,result_dir,project,fault,budget,crinosc,approach,budget,working_dir,project,fault)
			os.system(cmd1)
		else:
			print("(only patched classes)")
			cmd2 = 'perl ../bin/run_evosuite.pl -p {} -v {}f -n {} -o {}/suites/{}_{}/{} -c {} -h {} -b {} -t {}/{}_{} -a 450'.format(project,fault,trial,result_dir,project,fault,budget,crinosc,approach,budget,working_dir,project,fault)
			os.system(cmd2)
		                    
		print("----Measuring fault detection {}".format(budget))
		cmd3 = 'perl ../bin/run_bug_detection.pl -p {} -d {}/suites/{}_{}/{}/{}/evosuite-{}/{} -o {}/suites/{}_{}/{}/{}/evosuite-{} -f "**/*Test.java" -t {}/{}_{}'.format(project,result_dir,project,fault,budget,project,crinosc,trial,result_dir,project,fault,budget,project,crinosc,working_dir,project,fault)
		os.system(cmd3)
		
		cmd4 = 'rm -rf {}/{}_{}'.format(working_dir,project,fault)
		os.system(cmd4)
		
		
##############################



for project in projects:
	print("------------------------")
	print("-----Project ".format(project))
	# For each fault
	for fault in faults:
		fault=fault.strip()
		print("-----Fault #{}".format(fault))        
	# For each trial
		for trial in range(1, int(trials)+1):
			print("-----Trial #{}".format(trial))
			for budget in budgets:
				print("-----budget {}".format(budget))
				trial=str(trial)
				# Generate EvoSuite tests
				for criterion in criteria:
					crinosc = criterion.replace(":", "-").strip()
					CoreRun(project,fault,trial,budget,crinosc,"from main")
		
		GetInfo(project,fault,crinosc,trial, budget)
	cmd5 = 'tar cvzf {}_{}_rl.tgz {}/suites/{}_{}/'.format(project,fault,result_dir,project,fault)
	os.system(cmd5)					





















