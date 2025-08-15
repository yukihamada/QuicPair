#!/bin/bash

# Get local IP
IP=$(ipconfig getifaddr en0 || echo "localhost")
echo "Testing server at http://$IP:8080"

# Test connection endpoint
echo -e "\n1. Testing /connect endpoint:"
curl -v "http://$IP:8080/connect" 2>&1 | grep -E "(HTTP|{|error)"

# Test with localhost too
echo -e "\n2. Testing localhost:"
curl -v "http://localhost:8080/connect" 2>&1 | grep -E "(HTTP|{|error)"

# Check if server is listening
echo -e "\n3. Checking if port 8080 is open:"
lsof -i :8080

echo -e "\nDone!"