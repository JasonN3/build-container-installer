#!/bin/bash

vars=()

while read -r line
do
    if ! [[ $line =~ ^# ]]
    then
        vars+=$(echo $line | cut -d= -f1 | tr [:upper:] [:lower:])
    fi
    if [[ $line =~ ^########## ]]
    then
        break
    fi
done < Makefile

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