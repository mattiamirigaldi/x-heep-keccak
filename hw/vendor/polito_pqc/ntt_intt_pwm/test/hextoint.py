from math import log,ceil
from random import randint

import os
import sys


FILE_INPUT_TXT  = "DOUT_INTT_KEYB.txt"
FILE_OUTPUT_TXT  = "DOUT_INTT_INT_KEYB.txt"

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

int_list=[]
cnt=0


for line in INPUT_filename:

    hex_str = line.replace("\n","")
    int_value = int(hex_str, 16)
    # convert 16-bit two's complement to signed integer
    if int_value & 0x8000:
        int_value -= 0x10000
    
    int_list.append(int_value)

        
    OUTPUT_filename.write(str(int_value) + "\n")
    file_line=file_line+1


#----------------------------------CLOSE FILES-----------------------------------------------------------------------
OUTPUT_filename.close()
INPUT_filename.close()

#-----------------------------------------------------------THE END-----------------------------------------------------		
print("\nDone!\n")