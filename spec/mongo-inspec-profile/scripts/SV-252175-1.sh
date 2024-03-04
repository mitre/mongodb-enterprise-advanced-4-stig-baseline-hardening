#!/bin/bash

# Replace the placeholders with your actual MongoDB connection details and credentials
MONGO_HOST="localhost"
MONGO_PORT="27017"
#need these for later?
ADMIN_USER="admin"
ADMIN_PWD="admin"

# MongoDB command to create a read-only user
CREATE_USER_COMMAND="db.getSiblingDB('test').createUser({user: 'myTester', pwd: 'password', roles: [{role: 'read', db: 'test'}]})"

mongosh --host $MONGO_HOST --port $MONGO_PORT --quiet --eval "$CREATE_USER_COMMAND"
