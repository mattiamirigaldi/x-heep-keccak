##--------------------------------------------------------------------------------------------------##
## Copyright: Alessandra Dolmeta
## Politecnico di Torino, alessandra.dolmeta@polito.it
##--------------------------------------------------------------------------------------------------##

import os
import sys

FILE_INPUT_TXT  = "./pwm_test/pwm_DOUT3.txt"
FILE_OUTPUT_TXT  = "./pwm_DOUT3.txt"

##FILE_INPUT_TXT  = "./intt_test/intt_file.txt"
##FILE_OUTPUT_TXT  = "./intt_file.txt"

##FILE_INPUT_TXT  = "./ntt_test/ntt_file.txt"
##FILE_OUTPUT_TXT  = "./ntt_file.txt"

c_directory = os.getcwd()

INPUT_filename = os.path.join(c_directory, FILE_INPUT_TXT)
OUTPUT_filename= os.path.join(c_directory, FILE_OUTPUT_TXT)



try:
	INPUT_filename = open(INPUT_filename, 'r')
except:
	print("error: fail in opening file " + INPUT_filename + "\n")
	sys.exit()

try:
	OUTPUT_filename = open(OUTPUT_filename, 'w')
except:
	print("error: fail in opening file " + OUTPUT_filename + "\n")
	sys.exit()



file_line = 0
first_line=0

list_input=[]
list_out_VHDL=[]
cnt=0


for line in INPUT_filename:

    str1 = line.replace("\n","")
    
    for j in range(4-len(str1)):
        str1 = "0" + str1
        
    OUTPUT_filename.write(str1 + "\n")
    file_line=file_line+1


#----------------------------------CLOSE FILES-----------------------------------------------------------------------
OUTPUT_filename.close()
INPUT_filename.close()

#-----------------------------------------------------------THE END-----------------------------------------------------		
print("\nDone!\n")