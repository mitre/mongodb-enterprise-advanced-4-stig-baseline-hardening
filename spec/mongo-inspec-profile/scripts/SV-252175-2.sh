#!/bin/bash

# Replace the placeholders with your actual MongoDB connection details
MONGO_HOST="localhost"
MONGO_PORT="27017"
USER="myTester"
PWD="password"

# MongoDB command to attempt a write operation
WRITE_COMMAND="db.testCollection.insert({x: 1})"

# Attempt the write operation and capture the output
mongosh --host $MONGO_HOST --port $MONGO_PORT -u $USER -p $PWD --eval "use test; $WRITE_COMMAND"

#mongosh -u "myTester" -p "password" --authenticationMechanism SCRAM-SHA-256 --eval "use test; db.testCollection.insert({x: 1})"