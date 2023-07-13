#!/bin/bash

echo "optional parameter. (1) vsim gui, (0) vsim without gui"

run=$1

source /eda/scripts/init_questa
#source /software/europractice-release-2019/scripts/init_questa10.7c

echo "Questasim has been setup"
echo "Working directort $PWD"
vlib ./work

target="keccak.tcl"

if [ "$run" == '1' ]
then
	vsim -do ./$target 
elif [ "$run" == '0' ]
then 
	vsim -c -do ./$target 
else 
	vsim -c
fi 
