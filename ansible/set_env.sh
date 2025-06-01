#!/bin/bash

# Get the frontend server IP
FRONTEND_IP=$(terraform output -raw frontend_ip)
export FRONTEND_IP

# Get the vectordb server IP
VECTORDB_IP=$(terraform output -raw vectordb_ip)
export VECTORDB_IP

echo "Environment variables set:"
echo "FRONTEND_IP=$FRONTEND_IP"
echo "VECTORDB_IP=$VECTORDB_IP"