# -*- coding: utf-8 -*-
"""
Created on Sun Sep 29 21:43:55 2019

@author: Hussein
"""

import re
import os
import csv
from glob import glob

def GetFailTestInfo(filePath):
# Getting the failing information from the file and store it in array.
    failInfo = ["NA","NA","NA","NA","NA","NA","NA","NA","NA","NA"]
    with open(filePath) as csvfile:
        spamreader = csv.reader(csvfile, delimiter=',')
        next(spamreader)
        for row in spamreader:
            splitRow = ', '.join(row).split(",")
            #failInfo.insert(int(splitRow[3]), [splitRow[4],splitRow[5]])
                                         #[faultDetection,numOfFailing]
            failInfo[int(splitRow[3])-1] = [splitRow[4].strip() ,splitRow[5].strip()]
        return failInfo



outputFile = './results-8-smInfo.txt'
outfile  = open(outputFile, "w") 
#projs = "Math".split(",")

criteria = "STRONGMUTATION"


#for proj in projs:
projDir = "./results-8-sm/suites/"
outfile.write("Project,Fault,Trial,Criteria, Num_Second,Num_Generation,Num_Tests,Test_Length,SM_Coverage,Faults_Detected,Num_Failing-Tests \n")

for i in os.listdir(projDir):
    
    faultsDir = projDir + i
    
    if os.path.isdir(faultsDir):
        
        logDir = faultsDir + "/600/logs/*"       
        TestInfo = ["NA","NA","NA","NA","NA","NA","NA","NA","NA","NA"]
        for logFile in glob(logDir):
            d = logFile.split(".")
            if len(d) == 6:
                file  = open(logFile, "r") 
                text = file.read()
                proj = d[1].split("/")[-1]
                fault = d[2]
                criteria = d[3].replace(":", "-")
                trail = int(d[4])

		#[tmp_genLine[3], tmp_genLine[5], tmp_testSizeLine[1], tmp_testSizeLine[6], tmp_SMScore[1]]
                TestInfo[trail-1] = ["NA","NA","NA","NA","NA","NA"]
		TestInfo[trail-1][0] = criteria
                genLine = re.findall('Search finished after [0-9]+s and [0-9]+ generations', text)
		if(genLine):
		        for item in genLine:
		            tmp_genLine = str(item).split(" ")
			    TestInfo[trail-1][1] = tmp_genLine[3]
			    TestInfo[trail-1][2] = tmp_genLine[5]
		            break
		else:
			TestInfo[trail-1][1] = TestInfo[trail-1][2] = "NA"

                testSizeLine = re.findall('Generated [0-9]+ tests with total length [0-9]+', text)
		if(testSizeLine):
		        for item in testSizeLine:
		            tmp_testSizeLine = str(item).split(" ")
			    TestInfo[trail-1][3] = tmp_testSizeLine[1]
			    TestInfo[trail-1][4] = tmp_testSizeLine[6]
		            break
		else:
			TestInfo[trail-1][3] = TestInfo[trail-1][4] = "NA"
		           
                    
                SMScore = re.findall('Resulting test suite\'s mutation score: [0-9]+\%', text)
		if(SMScore):
		        for item in SMScore:
		            tmp_SMScore = str(item).split(":")
			    TestInfo[trail-1][5] = tmp_SMScore[1]
		            break
		else:
			TestInfo[trail-1][5] = "NA"

                                    
                file.close()
                
        failingTestInfo = GetFailTestInfo(faultsDir + "/600/"+proj+"/evosuite-"+criteria+"/bug_detection")
        for lop in range(0,10):
            if(failingTestInfo[lop] != "NA"):
                
                if(failingTestInfo[lop][0] == "Pass"):
                    fault_detection = 0
                elif(failingTestInfo[lop][0] == "Fail"):
                    fault_detection = 1
                else:
                    fault_detection = "-"
                num_failing = failingTestInfo[lop][1]
            else:
                 fault_detection = num_failing = "NA"
                 
            if(TestInfo[lop] != "NA"):
                criteria = TestInfo[lop][0]
                num_sec = TestInfo[lop][1].replace("s","")
                num_gen = TestInfo[lop][2]
                test_size = TestInfo[lop][3]
                test_len = TestInfo[lop][4]
                sm_score = TestInfo[lop][5].replace("%","").strip()
            else:
                 num_sec = num_gen = test_size = test_len = sm_score = "NA"
        
	    outfile.write("{},{},{},{},{},{},{},{},{},{},{}\n".format(proj, fault, lop+1, criteria,num_sec, num_gen, test_size, test_len, sm_score, fault_detection, num_failing))
        
outfile.close()




#get the missing results
with open(outputFile) as csvfile:
    spamreader = csv.reader(csvfile, delimiter=',')
    next(spamreader)
    Missing = []
    for row in spamreader:
        splitRow = ','.join(row).split(",")
        #failInfo.insert(int(splitRow[3]), [splitRow[4],splitRow[5]])
                                     #[faultDetection,numOfFailing]
        count = 0
        for i in range(3, 10):
            if (splitRow[i] == "NA"):
                count = count + 1
        if (count > 1 ):
            Missing.append([splitRow[0],splitRow[1], splitRow[2]])





