
## Middleware for tracking and logging API performance metrics.

import time
import logging
from flask import request, g
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('performance.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('performance')

class PerformanceMiddleware:
## Middleware to track response time for each request.
    
    def __init__(self, app):
        self.app = app
        self.setup_hooks()
        
        # Dictionary to store rolling averages for endpoints
        self.endpoint_stats = {}
    
    def setup_hooks(self):
    ## Set up before and after request hooks."""
        self.app.before_request(self.before_request)
        self.app.after_request(self.after_request)
        
    def before_request(self):
    ## Store the start time before processing the request
        g.start_time = time.time()
        
    def after_request(self, response):
    ## Calculate and log the request duration after processing
        # Skip for static files
        if request.path.startswith('/static'):
            return response
        
        # Calculate response time
        response_time = time.time() - g.start_time
        response_time_ms = round(response_time * 1000, 2)  # Convert to ms
        
        # Get the endpoint (route pattern) rather than specific URL
        endpoint = request.endpoint or 'unknown'
        
        # Update rolling statistics for this endpoint
        if endpoint not in self.endpoint_stats:
            self.endpoint_stats[endpoint] = {
                "count": 0,
                "total_time": 0,
                "min_time": float('inf'),
                "max_time": 0,
                "last_updated": datetime.now()
            }
        
        stats = self.endpoint_stats[endpoint]
        stats["count"] += 1
        stats["total_time"] += response_time
        stats["min_time"] = min(stats["min_time"], response_time)
        stats["max_time"] = max(stats["max_time"], response_time)
        stats["last_updated"] = datetime.now()
        
        # Log the response time
        logger.info(f"{request.method} {request.path} - {response.status_code} - {response_time_ms}ms")
        
        # Add performance header to response
        response.headers['X-Response-Time'] = f"{response_time_ms}ms"
        
        return response
    
    def get_stats(self):
    ## Return  performance statistics for all endpoints
        result = {}
        for endpoint, stats in self.endpoint_stats.items():
            avg_time = stats["total_time"] / stats["count"] if stats["count"] > 0 else 0
            result[endpoint] = {
                "count": stats["count"],
                "avg_time_ms": round(avg_time * 1000, 2),
                "min_time_ms": round(stats["min_time"] * 1000, 2) if stats["min_time"] != float('inf') else 0,
                "max_time_ms": round(stats["max_time"] * 1000, 2),
                "last_updated": stats["last_updated"].isoformat()
            }
        return result
        
def init_performance_middleware(app):
    ## Initialize the performance middleware with the Flask app
    middleware = PerformanceMiddleware(app)
    
    # Add endpoint to view performance stats
    @app.route('/performance-stats')
    def performance_stats():
        from flask import jsonify
        return jsonify(middleware.get_stats())
    
    return middleware