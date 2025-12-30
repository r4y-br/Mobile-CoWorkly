#!/bin/bash

BASE_URL="http://localhost:3000/api"

echo "Testing CoWorkly API..."
echo ""

# Test 1: Health Check
echo "1. Health Check:"
curl -s http://localhost:3000/health | jq '.' || echo "Failed"
echo ""

# Test 2: Sign Up
echo "2. Sign Up:"
SIGNUP_RESPONSE=$(curl -s -X POST $BASE_URL/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "Test@1234",
    "retypedPassword": "Test@1234",
    "phone": "1234567890"
  }')
echo $SIGNUP_RESPONSE | jq '.' || echo $SIGNUP_RESPONSE
ACCESS_TOKEN=$(echo $SIGNUP_RESPONSE | jq -r '.accessToken')
echo ""

# Test 3: Sign In
echo "3. Sign In:"
SIGNIN_RESPONSE=$(curl -s -X POST $BASE_URL/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test@1234"
  }')
echo $SIGNIN_RESPONSE | jq '.' || echo $SIGNIN_RESPONSE
ACCESS_TOKEN=$(echo $SIGNIN_RESPONSE | jq -r '.accessToken')
echo ""

# Test 4: Get Profile (Protected)
echo "4. Get Profile (Protected):"
curl -s -X GET $BASE_URL/auth/profile \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.' || echo "Failed"
echo ""

# Test 5: Invalid Token
echo "5. Test Invalid Token:"
curl -s -X GET $BASE_URL/auth/profile \
  -H "Authorization: Bearer invalid_token" | jq '.' || echo "Failed"
echo ""

echo "Tests completed!"
