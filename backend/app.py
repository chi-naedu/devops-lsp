from flask import Flask, request, jsonify, Blueprint
import redis
import hashlib
import os
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable Cross-Origin Resource Sharing for the frontend

# ------------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------------

# 1. Fetch Variables from Kubernetes Environment
redis_host = os.environ.get('REDIS_HOST', 'localhost')
redis_port = os.environ.get('REDIS_PORT', '6379')

# 2. Configure Redis Connection
try:
    r = redis.Redis(
        host=redis_host,
        port=int(redis_port),
        decode_responses=True,
        socket_connect_timeout=2
        # --- UNCOMMENT IF USING AWS ELASTICACHE ENCRYPTION ---
        # ssl=True,
        # ssl_cert_reqs=None 
    )
    # Optional: Quick ping to log connection status on startup
    r.ping()
    print(f"✅ Startup: Successfully connected to Redis at {redis_host}:{redis_port}")
except Exception as e:
    print(f"⚠️ Startup Warning: Could not connect to Redis: {e}")

# ------------------------------------------------------------------
# ROUTES
# ------------------------------------------------------------------

# Define the Blueprint for API routes
# This ensures these routes are accessible at /api/...
api = Blueprint('api', __name__, url_prefix='/api')

# --- GLOBAL ROUTE (Required for AWS ALB Health Checks) ---
@app.route('/', methods=['GET'])
def index():
    return jsonify({
        "status": "running", 
        "service": "linksnap-backend",
        "message": "Welcome to the LinkSnap API. Use /api/shorten to create links."
    }), 200

# --- API ROUTES (Grouped under /api) ---

@api.route('/health', methods=['GET'])
def health():
    """
    Checks if the backend can talk to Redis.
    Access at: GET /api/health
    """
    try:
        r.ping()
        db_status = "connected"
    except Exception as e:
        db_status = f"disconnected: {str(e)}"

    return jsonify({
        "status": "healthy", 
        "service": "backend",
        "redis": db_status
    }), 200

@api.route('/shorten', methods=['POST'])
def shorten_url():
    """
    Creates a short link.
    Access at: POST /api/shorten
    """
    data = request.get_json()
    original_url = data.get('url')
    
    if not original_url:
        return jsonify({"error": "URL is required"}), 400

    # Generate a short 6-character hash
    short_id = hashlib.md5(original_url.encode()).hexdigest()[:6]
    
    try:
        # Store in Redis: Key=short_id, Value=original_url
        r.set(short_id, original_url)
        return jsonify({"short_id": short_id, "original_url": original_url}), 201
    except Exception as e:
        return jsonify({"error": "Database error", "details": str(e)}), 500

@api.route('/<short_id>', methods=['GET'])
def redirect_url(short_id):
    """
    Retrieves the original URL.
    Access at: GET /api/<short_id>
    """
    try:
        original_url = r.get(short_id)
        if original_url:
            return jsonify({"original_url": original_url}), 200
        else:
            return jsonify({"error": "URL not found"}), 404
    except Exception as e:
         return jsonify({"error": "Database error", "details": str(e)}), 500

# 3. Register the Blueprint to the main App
app.register_blueprint(api)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)