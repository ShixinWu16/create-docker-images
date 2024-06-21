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
            tr -d '\n' < $doc | mongoimport --db $dbname --collection $collection --uri "mongodb://root:admin@mongodb:27017/supremm?authSource=admin" --authenticationDatabase admin
        done
    done
done
