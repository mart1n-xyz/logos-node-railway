#!/usr/bin/env bash
# entrypoint.sh — Logos Blockchain node startup script for Railway
#
# First run:  generates keys + user_config.yaml via `init`, then starts node.
# Later runs: skips init and starts directly from the existing config.
#
# Environment variables (all optional — see railway.toml for defaults):
#   BOOTSTRAP_PEERS   Space-separated multiaddrs for the devnet bootstrap peers.
#   P2P_PORT          UDP port for libp2p/QUIC (default: 3000).
#   API_PORT          TCP port for the HTTP API   (default: 8080).
#   DATA_DIR          Directory for config + chain state (default: /data).

set -euo pipefail

DATA_DIR="${DATA_DIR:-/data}"
P2P_PORT="${P2P_PORT:-3000}"
API_PORT="${API_PORT:-8080}"
CONFIG_FILE="${DATA_DIR}/user_config.yaml"

# Ensure the data directory exists (volume may not be pre-populated)
mkdir -p "${DATA_DIR}"

# ── Graceful shutdown ──────────────────────────────────────────────────────────
_shutdown() {
    echo "[entrypoint] Caught SIGTERM — shutting down node (PID ${NODE_PID})..."
    kill -TERM "${NODE_PID}" 2>/dev/null || true
    wait "${NODE_PID}" 2>/dev/null || true
    echo "[entrypoint] Node stopped."
    exit 0
}

# ── First-run initialisation ───────────────────────────────────────────────────
if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "[entrypoint] No config found — running first-time initialisation..."

    if [[ -z "${BOOTSTRAP_PEERS:-}" ]]; then
        echo "[entrypoint] WARNING: BOOTSTRAP_PEERS is not set. Node may not be able to join the network."
    fi

    # Build the --bootstrap-peers flags (one flag per peer)
    PEER_FLAGS=()
    for peer in ${BOOTSTRAP_PEERS:-}; do
        PEER_FLAGS+=(--bootstrap-peers "${peer}")
    done

    logos-blockchain-node init \
        --data-path "${DATA_DIR}" \
        "${PEER_FLAGS[@]+"${PEER_FLAGS[@]}"}"

    echo "[entrypoint] Initialisation complete. Config written to ${CONFIG_FILE}."
else
    echo "[entrypoint] Existing config found at ${CONFIG_FILE} — skipping init."
fi

# ── Start the node ─────────────────────────────────────────────────────────────
echo "[entrypoint] Starting Logos Blockchain node..."
echo "[entrypoint]   Data dir : ${DATA_DIR}"
echo "[entrypoint]   P2P port : ${P2P_PORT}/udp (QUIC)"
echo "[entrypoint]   API port : ${API_PORT}/tcp"
echo "[entrypoint]   Circuits : ${LOGOS_BLOCKCHAIN_CIRCUITS}"

logos-blockchain-node \
    --config "${CONFIG_FILE}" \
    --data-path "${DATA_DIR}" \
    --p2p-port "${P2P_PORT}" \
    --api-port "${API_PORT}" &

NODE_PID=$!
echo "[entrypoint] Node started (PID ${NODE_PID})."

trap '_shutdown' SIGTERM SIGINT

# Wait for the node process; propagate its exit code
wait "${NODE_PID}"
EXIT_CODE=$?
echo "[entrypoint] Node exited with code ${EXIT_CODE}."
exit "${EXIT_CODE}"
