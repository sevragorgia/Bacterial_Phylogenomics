#!/bin/bash

########################################
#Copyright 2018 Sergio Vargas
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program. If not, see <http://www.gnu.org/licenses/>.
#
#
#based on code from
#https://stackoverflow.com/questions/10929453/read-a-file-line-by-line-assigning-the-value-to-a-variable
#while IFS='' read -r line || [[ -n "$line" ]]; do
#    echo "Text read from file: $line"
#done < "$1"
#
#assumes you provide a file with one ftp address per line
#the ftp address should look like
#
#ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/218/545/GCF_000218545.1_ASM21854v1/
#
#######################################################################################################################


while IFS='' read -r line || [[ -n "$line" ]]; do

    echo "downloading $genome"
    
    genome=`echo $line | cut -f 10 -d /`
    
    mkdir $genome
    cd $genome
    
    wget ${line}/*
    
    cd ../

done < "$1"
