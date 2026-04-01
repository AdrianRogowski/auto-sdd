# /clean-slate — Kill Dev Servers and Restart

Kill all processes running on development ports and optionally restart the dev server.

## What This Command Does

1. **Find processes** on common dev ports (3000, 3001, 4000, 5173, 5174, 8000, 8080, 8888)
2. **Kill them** all
3. **Optionally restart** the dev server

---

## Instructions

### Step 1: Check for Running Processes

Run:
```bash
./scripts/clean-slate.sh
```

If `DEV_PORTS` is set in `.env.local`, use those ports. Otherwise use the defaults.

Also check for common dev process names that might be on non-standard ports:
```bash
# Check for node/next/vite/python processes
ps aux | grep -E 'node|next-server|vite|uvicorn|gunicorn|flask|django' | grep -v grep
```

If extra processes are found on non-standard ports, ask the user if they should be killed too.

### Step 2: Report What Was Killed

```
✓ Killed 3 processes:
  - Port 3000: node (PID 12345) — next-server
  - Port 5173: node (PID 12346) — vite
  - Port 8080: python (PID 12347) — uvicorn

  All dev ports clear.
```

### Step 3: Ask About Restart

If the user said `/clean-slate` without further context:
- Ask if they want to restart the dev server
- If yes, detect the start command and run it

If the user said `/clean-slate --restart` or "clean slate and restart":
- Auto-detect the dev command from package.json or DEV_CMD in .env.local
- Run it in background (block_until_ms: 0)
- Wait 3-5 seconds, then check if it started successfully

### Step 4: Verify

After restart, verify the server is up:
```bash
# Wait for the server to be ready
sleep 3
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 || echo "not ready yet"
```

Report:
```
✓ Dev server running on http://localhost:3000
```

---

## Quick Usage

```
/clean-slate                    — Kill all dev ports
/clean-slate --restart          — Kill and restart
/clean-slate 3000 5173          — Kill specific ports only
```

## Configuration

In `.env.local`:
```bash
DEV_PORTS="3000,5173"           # Ports to kill (default: common dev ports)
DEV_CMD="pnpm dev"              # Command to start dev server
```

These are set automatically by `/ralph-setup`.
