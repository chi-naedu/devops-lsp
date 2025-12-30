import React, { useState } from 'react';
import './App.css';

function App() {
  const [url, setUrl] = useState('');
  const [shortUrl, setShortUrl] = useState('');
  const [error, setError] = useState('');

  // Depending on where this runs, the backend URL changes
  // For local docker-compose, we usually proxy or point directly
  const BACKEND_URL = process.env.REACT_APP_BACKEND_URL || 'http://localhost:5001';

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setShortUrl('');

    try {
      const response = await fetch(`${BACKEND_URL}/shorten`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url }),
      });

      const data = await response.json();
      if (response.ok) {
        setShortUrl(`${BACKEND_URL}/${data.short_id}`);
      } else {
        setError(data.error || 'Something went wrong');
      }
    } catch (err) {
      setError('Failed to connect to backend');
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>LinkSnap</h1>
        <p>The DevOps URL Shortener</p>
        
        <form onSubmit={handleSubmit}>
          <input
            type="text"
            placeholder="Enter long URL..."
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            style={{ padding: '10px', width: '300px' }}
          />
          <button type="submit" style={{ padding: '10px 20px', marginLeft: '10px' }}>
            Snap it!
          </button>
        </form>

        {shortUrl && (
          <div style={{ marginTop: '20px', color: 'lightgreen' }}>
            <p>Shortened URL:</p>
            <a href={shortUrl} target="_blank" rel="noopener noreferrer" style={{ color: 'white' }}>
              {shortUrl}
            </a>
          </div>
        )}

        {error && <p style={{ color: 'red', marginTop: '20px' }}>{error}</p>}
      </header>
    </div>
  );
}

export default App;