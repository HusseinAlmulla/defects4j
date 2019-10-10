import mysql.connector
from mysql.connector import Error
import pandas as pd
from panda import DataFrame




try:
	connection = mysql.connector.connect(host='expdata.cimqzxtw4rae.us-east-1.rds.amazonaws.com',
						database='expr_data_result',
						user='admin',
						password='ExpRun2019AWS')

	if connection.is_connected():
		print("Connected ...")		
		print("read from the table ...")
	
		sql = """select * from  expr_data_result`.`Data_results"""
		results = pd.read_sql(sql,connection)
		results = results.to_csv(r'./Allresults.csv', header=True)
		print("Done ...")
except Error as e:
	print("Error ...")
	outfile  = open('./Error_log.txt', "a")
	outfile.write("	Error while connecting to MySQL {} for values".format(e, values))
	outfile.close()
finally:
	if (connection.is_connected()):
		connection.close()
		print("MySQL connection is closed")
