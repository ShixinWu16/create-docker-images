#!/bin/bash

BASEPATH=~/assets/referencedata/mongo

for dbpath in $BASEPATH/*
do
    dbname=`basename $dbpath`
    for collectionpath in $dbpath/*
    do
        collection=`basename $collectionpath`
        for doc in $collectionpath/*.json
        do
            tr -d '\n' < $doc | mongoimport --db $dbname --collection $collection --uri "mongodb://admin:QQtggS+mU4d50+hT7GzfM@mongodb:27017/supremm?authSource=auth"
        done
    done
done
