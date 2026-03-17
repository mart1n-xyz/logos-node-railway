# Logos Blockchain Node — Railway Template

Run a [Logos Blockchain](https://github.com/logos-co/nomos-node) devnet node on [Railway](https://railway.app) in one click.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/vhzp1z?referralCode=TSm7KN)

> **One-click deploy** → Railway pulls this repo, builds the Docker image (downloading the node binary + ZK circuits from GitHub Releases), provisions a persistent volume, and starts the node.

---

## What this is

This template runs a single **Logos Blockchain** full node on Railway. It:

- Downloads the official `logos-blockchain-node` binary and ZK circuit files from GitHub Releases at image build time.
- Runs `logos-blockchain-node init` on first boot to generate fresh keys and a `user_config.yaml`.
- Stores config and all chain state on a Railway persistent volume (`/data`) so data survives redeploys.
- Exposes a **web dashboard** on the Railway public URL (port 3001) with live node status, peer info, wallet keys, and scrolling logs.
- Runs the node HTTP API on port 8080 internally (not publicly exposed).
- Uses p2p (UDP/QUIC) on port 3000.

---

## Web Dashboard

Once deployed, open your Railway public URL in a browser to see the dashboard:

- **Node Status** — mode, current slot, block height, and chain tip hash (from `/cryptarchia/info`)
- **Network / Peers** — connected peer count and connection count (from `/network/info`)
- **Wallet Keys** — public keys from `user_config.yaml`
- **Node Logs** — last 500 lines, auto-scrolling, color-coded for errors and warnings
- **Auto-refresh** every 10 seconds

### Dashboard API endpoints

| Endpoint | Description |
|---|---|
| `GET /` | HTML dashboard |
| `GET /api/status` | JSON combining cryptarchia/info + network/info |
| `GET /api/logs` | Last 500 log lines as JSON |
| `GET /api/keys` | Node public keys from config |

### Password protection

Set the `DASHBOARD_PASSWORD` environment variable to enable HTTP basic auth:

- Username: `admin`
- Password: whatever you set in `DASHBOARD_PASSWORD`

If `DASHBOARD_PASSWORD` is empty (the default), the dashboard is publicly accessible.

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `PORT` | `3001` | Web dashboard port (Railway routes public traffic here) |
| `NODE_API_PORT` | `8080` | Internal node HTTP API port |
| `API_PORT` | `8080` | Same as `NODE_API_PORT` — used by the node binary |
| `DATA_DIR` | `/data` | Persistent volume mount path |
| `DASHBOARD_PASSWORD` | *(empty)* | If set, enables basic auth on the dashboard |
| `BOOTSTRAP_PEERS` | *(v0.2.1 peers — see below)* | Space-separated multiaddrs to join the network |

### Default bootstrap peers (v0.2.1)

```
/ip4/65.109.51.37/udp/3000/quic-v1/p2p/12D3KooWL7a8LBbLRYnabptHPFBCmAs49Y7cVMqvzuSdd43tAJk8
/ip4/65.109.51.37/udp/3001/quic-v1/p2p/12D3KooWPLeAcachoUm68NXGD7tmNziZkVeMmeBS5NofyukuMRJh
/ip4/65.109.51.37/udp/3002/quic-v1/p2p/12D3KooWKFNe4gS5DcCcRUVGdMjZp3fUWu6q6gG5R846Ui1pccHD
/ip4/65.109.51.37/udp/3003/quic-v1/p2p/12D3KooWAnriLgXyQnGTYz1zPWPkQL3rthTKYLzuAP7MMnbgsxzR
```

---

## Getting devnet tokens

Visit the Logos faucet (link in the [official docs](https://github.com/logos-co/nomos-node)) and paste your node's public key — visible in the **Wallet Keys** card on the dashboard, or in `/data/user_config.yaml` on the volume.

---

## Updating to a new release

1. In your Railway project, go to **Settings → Variables** and update `BOOTSTRAP_PEERS` to the peers listed in the new release notes.
2. Open `railway.toml` in this repo, update `NODE_VERSION` (and `CIRCUITS_VERSION` if the circuits were re-released), then push to your fork.
3. Railway will automatically rebuild the image and redeploy. Chain state on `/data` is preserved.

> **Tip**: If `CIRCUITS_VERSION` differs from `NODE_VERSION` in a release, set them independently in `railway.toml` under `[build.args]`.

---

## Repository structure

```
.
├── Dockerfile       # Multi-stage build — downloads binary + circuits from GitHub Releases
├── entrypoint.sh    # Handles first-run init, log capture, graceful shutdown
├── dashboard.py     # Python stdlib HTTP server (status, logs, keys, optional auth)
├── dashboard.html   # Dark-themed single-page dashboard with auto-refresh
├── railway.toml     # Railway config: volume, health check, env var defaults
└── README.md        # This file
```

---

## License

MIT
