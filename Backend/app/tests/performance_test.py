#!/usr/bin/env python

## Performance Testing Script for Female Health App API
## This script measures response times and latency for various API endpoints.

import requests
import time
import statistics
import json
from datetime import datetime
import sys
import os

# Add the parent directory to the path so we can import app modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

# Base URL for API requests
BASE_URL = "http://127.0.0.1:5000"
TEST_USER_ID = "L1yhhfQr50hDacTRTP120BQtq0i1"  

def measure_endpoint_performance(endpoint, method="GET", data=None, iterations=10):
## Measure the response time of an endpoint over multiple requests
    url = f"{BASE_URL}/{endpoint}"
    response_times = []
    status_codes = []
    
    print(f"\nTesting {method} {endpoint}")
    print("-" * 50)
    
    for i in range(iterations):
        start_time = time.time()
        
        if method == "GET":
            response = requests.get(url)
        elif method == "POST":
            response = requests.post(url, json=data)
        elif method == "PUT":
            response = requests.put(url, json=data)
        else:
            raise ValueError(f"Unsupported HTTP method: {method}")
        
        end_time = time.time()
        response_time = (end_time - start_time) * 1000  # Convert to milliseconds
        
        response_times.append(response_time)
        status_codes.append(response.status_code)
        
        print(f"Request {i+1}/{iterations}: {response_time:.2f}ms (Status: {response.status_code})")
        
    # Calculate statistics
    avg_response_time = statistics.mean(response_times)
    median_response_time = statistics.median(response_times)
    min_response_time = min(response_times)
    max_response_time = max(response_times)
    stddev = statistics.stdev(response_times) if len(response_times) > 1 else 0
    
    results = {
        "endpoint": endpoint,
        "method": method,
        "iterations": iterations,
        "avg_response_time_ms": round(avg_response_time, 2),
        "median_response_time_ms": round(median_response_time, 2),
        "min_response_time_ms": round(min_response_time, 2),
        "max_response_time_ms": round(max_response_time, 2),
        "std_deviation_ms": round(stddev, 2),
        "success_rate": f"{status_codes.count(200)}/{iterations}"
    }
    
    print("\nResults:")
    print(f"Average response time: {avg_response_time:.2f}ms")
    print(f"Median response time: {median_response_time:.2f}ms")
    print(f"Min response time: {min_response_time:.2f}ms")
    print(f"Max response time: {max_response_time:.2f}ms")
    print(f"Standard deviation: {stddev:.2f}ms")
    print(f"Success rate: {status_codes.count(200)}/{iterations}")
    
    return results

def run_performance_tests():
## Run performance tests on various endpoints
    results = []
    test_timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # Define test cases - endpoint, method, data
    test_cases = [
        # User and authentication endpoints
        {"endpoint": "login", "method": "POST", "data": {"email": "testuser@example.com", "password": "testpassword1"}},
        
        # Cycle info endpoints
        {"endpoint": f"get_current_cycle_info/{TEST_USER_ID}", "method": "GET"},
        {"endpoint": f"get_cycles/{TEST_USER_ID}", "method": "GET"},
        
        # Mood endpoints
        {"endpoint": f"get_moods/{TEST_USER_ID}", "method": "GET"},
        {"endpoint": "log_mood", "method": "POST", "data": {
            "user_id": TEST_USER_ID,
            "mood": "Happy",
            "energy_level": 8,
            "notes": "Performance testing"
        }},
        
        # Analytics endpoints
        {"endpoint": f"get_energy_levels_by_phase/{TEST_USER_ID}", "method": "GET"},
        {"endpoint": f"get_feelings_by_phase/{TEST_USER_ID}", "method": "GET"},
        {"endpoint": f"get_analytics/{TEST_USER_ID}", "method": "GET"},
    ]
    
    for test_case in test_cases:
        result = measure_endpoint_performance(
            test_case["endpoint"], 
            test_case["method"], 
            test_case.get("data"),
            iterations=5  
        )
        results.append(result)
    
    # Save results to a JSON file
    output_file = f"performance_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(output_file, "w") as f:
        json.dump({
            "timestamp": test_timestamp,
            "results": results
        }, f, indent=2)
    
    print(f"\nAll test results saved to {output_file}")
    
    # Calculate overall statistics
    avg_times = [r["avg_response_time_ms"] for r in results]
    
    print("\nOverall Performance Summary:")
    print(f"Average response time across all endpoints: {statistics.mean(avg_times):.2f}ms")
    print(f"Fastest endpoint: {results[avg_times.index(min(avg_times))]['endpoint']} ({min(avg_times):.2f}ms)")
    print(f"Slowest endpoint: {results[avg_times.index(max(avg_times))]['endpoint']} ({max(avg_times):.2f}ms)")

if __name__ == "__main__":
    print("Starting Performance Tests")
    print("=" * 50)
    run_performance_tests()