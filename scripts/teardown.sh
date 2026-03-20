#!/bin/bash
# =============================================================================
# Cloud Workstation — Teardown / Cleanup
# =============================================================================
# Deletes ALL resources created by setup.sh. Use to clean up a project
# completely or before re-testing setup from scratch.
#
# Usage:
#   bash scripts/teardown.sh -p PROJECT_ID [--webhook URL]
#
# This runs directly (not in Cloud Build) since teardown is fast.
# =============================================================================

set -euo pipefail

REGION="us-west1"
CLUSTER="workstation-cluster"
CONFIG="ws-config"
WORKSTATION="dev-workstation"
AR_REPO="workstation-images"

usage() {
    echo "Usage: bash scripts/teardown.sh -p PROJECT_ID [--webhook URL]"
    echo ""
    echo "Deletes ALL Cloud Workstation resources created by setup.sh."
    echo ""
    echo "Required:"
    echo "  -p, --project PROJECT_ID    GCP project ID"
    echo ""
    echo "Optional:"
    echo "  -w, --webhook URL           Google Chat webhook for notifications"
    echo "  -y, --yes                   Skip confirmation prompt"
    exit 1
}

PROJECT_ID=""
WEBHOOK_URL=""
SKIP_CONFIRM=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project) PROJECT_ID="$2"; shift 2 ;;
        -w|--webhook) WEBHOOK_URL="$2"; shift 2 ;;
        -y|--yes) SKIP_CONFIRM=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

if [ -z "$PROJECT_ID" ]; then
    echo "ERROR: --project is required"
    usage
fi

log() { echo "[$(date '+%H:%M:%S')] $1"; }

notify() {
    [ -z "$WEBHOOK_URL" ] && return 0
    curl -s -X POST "$WEBHOOK_URL" \
        -H 'Content-Type: application/json' \
        -d "{
            \"cards\": [{
                \"header\": {\"title\": \"$1\", \"subtitle\": \"$2\"},
                \"sections\": [{\"widgets\": [{\"textParagraph\": {\"text\": \"$3\"}}]}]
            }]
        }" >/dev/null 2>&1 || true
}

echo "============================================="
echo " Cloud Workstation TEARDOWN"
echo " Project: $PROJECT_ID"
echo "============================================="
echo ""
echo " This will DELETE the following resources:"
echo "   - Workstation: $WORKSTATION"
echo "   - Workstation Config: $CONFIG"
echo "   - Workstation Cluster: $CLUSTER"
echo "   - Artifact Registry: $AR_REPO (and all images)"
echo "   - Cloud NAT: ws-nat"
echo "   - Cloud Router: ws-router"
echo "   - Cloud Scheduler: ws-daily-start"
echo ""

if [ "$SKIP_CONFIRM" = false ]; then
    read -p "Are you sure? This cannot be undone. (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi
fi

echo ""
notify "Teardown Started" "Project: ${PROJECT_ID}" "Deleting all Cloud Workstation resources..."

# --- 1. Delete Workstation ---
log "Deleting workstation '$WORKSTATION'..."
if gcloud workstations describe "$WORKSTATION" \
    --config="$CONFIG" --cluster="$CLUSTER" --region="$REGION" \
    --project="$PROJECT_ID" >/dev/null 2>&1; then
    # Stop first if running
    gcloud workstations stop "$WORKSTATION" \
        --config="$CONFIG" --cluster="$CLUSTER" --region="$REGION" \
        --project="$PROJECT_ID" --quiet 2>/dev/null || true
    gcloud workstations delete "$WORKSTATION" \
        --config="$CONFIG" --cluster="$CLUSTER" --region="$REGION" \
        --project="$PROJECT_ID" --quiet 2>/dev/null
    log "  Deleted workstation"
else
    log "  Workstation not found — skipping"
fi

# --- 2. Delete Workstation Config ---
log "Deleting config '$CONFIG'..."
if gcloud workstations configs describe "$CONFIG" \
    --cluster="$CLUSTER" --region="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
    gcloud workstations configs delete "$CONFIG" \
        --cluster="$CLUSTER" --region="$REGION" \
        --project="$PROJECT_ID" --quiet 2>/dev/null
    log "  Deleted config"
else
    log "  Config not found — skipping"
fi

# --- 3. Delete Workstation Cluster ---
log "Deleting cluster '$CLUSTER' (this takes 5-10 minutes)..."
if gcloud workstations clusters describe "$CLUSTER" \
    --region="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
    gcloud workstations clusters delete "$CLUSTER" \
        --region="$REGION" --project="$PROJECT_ID" --quiet 2>/dev/null
    log "  Deleted cluster"
else
    log "  Cluster not found — skipping"
fi

# --- 4. Delete Artifact Registry (and all images) ---
log "Deleting Artifact Registry '$AR_REPO'..."
if gcloud artifacts repositories describe "$AR_REPO" \
    --location="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
    gcloud artifacts repositories delete "$AR_REPO" \
        --location="$REGION" --project="$PROJECT_ID" --quiet 2>/dev/null
    log "  Deleted Artifact Registry"
else
    log "  Artifact Registry not found — skipping"
fi

# --- 5. Delete Cloud NAT ---
log "Deleting Cloud NAT 'ws-nat'..."
if gcloud compute routers nats describe ws-nat \
    --router=ws-router --region="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
    gcloud compute routers nats delete ws-nat \
        --router=ws-router --region="$REGION" \
        --project="$PROJECT_ID" --quiet 2>/dev/null
    log "  Deleted Cloud NAT"
else
    log "  Cloud NAT not found — skipping"
fi

# --- 6. Delete Cloud Router ---
log "Deleting Cloud Router 'ws-router'..."
if gcloud compute routers describe ws-router \
    --region="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
    gcloud compute routers delete ws-router \
        --region="$REGION" --project="$PROJECT_ID" --quiet 2>/dev/null
    log "  Deleted Cloud Router"
else
    log "  Cloud Router not found — skipping"
fi

# --- 7. Delete Cloud Scheduler ---
log "Deleting Cloud Scheduler 'ws-daily-start'..."
if gcloud scheduler jobs describe ws-daily-start \
    --location="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
    gcloud scheduler jobs delete ws-daily-start \
        --location="$REGION" --project="$PROJECT_ID" --quiet 2>/dev/null
    log "  Deleted Cloud Scheduler"
else
    log "  Cloud Scheduler not found — skipping"
fi

echo ""
echo "============================================="
echo " Teardown complete!"
echo "============================================="
echo ""
echo " All Cloud Workstation resources have been deleted."
echo " To set up again, run:"
echo "   bash scripts/setup.sh -p $PROJECT_ID"
echo "============================================="

notify "Teardown Complete" "Project: ${PROJECT_ID}" "All Cloud Workstation resources deleted. Project is clean."
