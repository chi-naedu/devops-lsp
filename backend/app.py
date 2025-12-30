from flask import Flask, request, jsonify, redirect
import redis
import hashlib
import os
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable Cross-Origin Resource Sharing for the frontend

# Connect to Redis (Hostname 'redis' is defined in docker-compose)
# In production K8s, this will come from an Environment Variable
redis_host = os.environ.get('REDIS_HOST', 'redis')
r = redis.Redis(host=redis_host, port=6379, decode_responses=True)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy", "service": "backend"}), 200

@app.route('/shorten', methods=['POST'])
def shorten_url():
    data = request.get_json()
    original_url = data.get('url')
    
    if not original_url:
        return jsonify({"error": "URL is required"}), 400

    # Generate a short 6-character hash
    short_id = hashlib.md5(original_url.encode()).hexdigest()[:6]
    
    # Store in Redis: Key=short_id, Value=original_url
    r.set(short_id, original_url)
    
    return jsonify({"short_id": short_id, "original_url": original_url}), 201

@app.route('/<short_id>', methods=['GET'])
def redirect_url(short_id):
    original_url = r.get(short_id)
    if original_url:
        # In a real app, you'd redirect. For this API demo, we return the URL.
        # return redirect(original_url) 
        return jsonify({"original_url": original_url}), 200
    else:
        return jsonify({"error": "URL not found"}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)