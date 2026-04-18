#!/bin/bash
# Start the backend server locally

cd "$(dirname "$0")"

# Create data directory
mkdir -p data

# Install dependencies if needed
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
else
    source .venv/bin/activate
fi

# Run server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000