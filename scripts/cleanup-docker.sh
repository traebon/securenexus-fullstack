#!/bin/bash
# Docker Cleanup & Maintenance Script
# Safely removes unused Docker resources

set -e

echo "🧹 Docker Cleanup & Maintenance"
echo "================================"
echo ""

# Show current usage
echo "📊 Current Docker disk usage:"
docker system df
echo ""

# 1. Remove dangling images
echo "🗑️  Removing dangling images..."
DANGLING=$(docker image prune -f --filter "dangling=true" 2>&1)
echo "$DANGLING"
echo ""

# 2. Remove unused images (not associated with any container)
echo "🗑️  Removing unused images..."
read -p "Remove all unused images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker image prune -a -f
    echo "✅ Unused images removed"
else
    echo "ℹ️  Skipped unused image removal"
fi
echo ""

# 3. Remove unused volumes
echo "🗑️  Checking unused volumes..."
UNUSED_VOLUMES=$(docker volume ls -qf dangling=true | wc -l)
if [ "$UNUSED_VOLUMES" -gt 0 ]; then
    echo "Found $UNUSED_VOLUMES unused volumes"
    read -p "Remove unused volumes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker volume prune -f
        echo "✅ Unused volumes removed"
    else
        echo "ℹ️  Skipped volume removal"
    fi
else
    echo "✅ No unused volumes found"
fi
echo ""

# 4. Remove build cache
echo "🗑️  Removing build cache..."
docker builder prune -f
echo "✅ Build cache cleared"
echo ""

# 5. Remove stopped containers (exclude running)
echo "🗑️  Checking stopped containers..."
STOPPED=$(docker ps -a -q -f status=exited | wc -l)
if [ "$STOPPED" -gt 0 ]; then
    echo "Found $STOPPED stopped containers"
    docker container prune -f
    echo "✅ Stopped containers removed"
else
    echo "✅ No stopped containers found"
fi
echo ""

# Final status
echo "📊 Final Docker disk usage:"
docker system df
echo ""
echo "✅ Cleanup complete!"
echo ""
echo "💡 Tips:"
echo "  - Run this weekly to maintain disk space"
echo "  - Add to cron: 0 3 * * 0 /home/tristian/securenexus-fullstack/scripts/cleanup-docker.sh"
echo "  - Monitor with: docker system df"
