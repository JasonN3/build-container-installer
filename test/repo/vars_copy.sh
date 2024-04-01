#!/bin/bash

exit 0

makefile = open('../../Makefile.inputs', 'r')
makefile_lines = makefile.readlines()

vars = []

for line in makefile_lines:
    if line.startswith('#'):
        makefile_lines.remove(line)
    parts = line.split('=', 1)
    vars += { parts[0]: parts[1] }

print(vars)

vars=()
default_values=()

while read -r line
do
    if ! [[ $line =~ ^# ]]
    then
        vars+=$(echo $line | cut -d= -f1 | tr [:upper:] [:lower:])
    fi
done < ../../Makefile.inputs

result=0

for var in $vars
do
    grep "^| ${var}" README.md > /dev/null
    if [[ $? != 0 ]]
    then
        echo "$var not found in README.md"
        result=1
    fi
done

for var in $vars
do
    grep "^  ${var}:" action.yml > /dev/null
    if [[ $? != 0 ]]
    then
        echo "$var not found in action.yml"
        result=1
    fi
done

exit ${result}