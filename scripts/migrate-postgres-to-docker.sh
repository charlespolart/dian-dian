#!/bin/bash
# One-time migration: native Postgres on the VPS → Docker Postgres.
# Run this ON THE VPS, not locally. Make sure git is up to date and the
# next CI deploy hasn't started yet (or has finished).
#
# Usage: sudo bash scripts/migrate-postgres-to-docker.sh

set -euo pipefail

DUMP=/tmp/dian_dian_$(date +%Y%m%d_%H%M%S).sql
ENV=/root/dian-dian/backend/.env

echo "==> Dumping native Postgres to $DUMP"
sudo -u postgres pg_dump dian_dian > "$DUMP"
echo "    size: $(du -h "$DUMP" | cut -f1)"

echo "==> Stopping & disabling native Postgres"
sudo systemctl stop postgresql
sudo systemctl disable postgresql

echo "==> Updating .env DATABASE_URL port 5432 → 5433"
sed -i 's|localhost:5432/|localhost:5433/|' "$ENV"

echo "==> Starting Docker Postgres"
cd /root/dian-dian
sudo docker compose up -d postgres

echo "==> Waiting for Postgres to accept connections"
for i in $(seq 1 30); do
  if sudo docker compose exec -T postgres pg_isready -U postgres -d dian_dian >/dev/null 2>&1; then
    echo "    ready after ${i}s"
    break
  fi
  sleep 1
done

echo "==> Restoring dump into Docker Postgres"
cat "$DUMP" | sudo docker compose exec -T postgres psql -U postgres -d dian_dian >/dev/null

echo "==> Restarting backend to pick up the new DATABASE_URL"
sudo docker compose restart backend

echo "==> Done. Verify:"
echo "    sudo docker compose logs --tail=50 backend"
echo "    sudo docker compose exec postgres psql -U postgres -d dian_dian -c 'SELECT count(*) FROM users;'"
echo
echo "Once verified, you can purge the native Postgres install:"
echo "    sudo apt purge -y postgresql-16 postgresql-client-16 postgresql-common"
echo "    sudo rm -rf /var/lib/postgresql /etc/postgresql"
