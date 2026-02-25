#!/bin/bash
# Goksori Service Nuclear Reset Script

echo "🛑 Stopping goksori service..."
systemctl stop goksori

echo "💀 Killing any remaining python processes..."
pkill -9 python || true

echo "🧹 Cleaning up corrupted database and caches..."
rm -f /home/goksori/backend/goksori.db
find /home/goksori/backend -name "__pycache__" -type d -exec rm -rf {} +

echo "🚀 Restarting goksori service..."
systemctl daemon-reload
systemctl start goksori

echo "📊 Current Status:"
systemctl status goksori --no-pager

echo ""
echo "✅ Reset Complete. Please check the website in 1-2 minutes."
