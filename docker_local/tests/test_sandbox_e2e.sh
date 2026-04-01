#!/usr/bin/env bash
# DeerFlow E2E Test: Task Dispatch to Sandbox
# Tests the complete flow: create thread → send task → sandbox execution

set -e

# Configuration
BASE_URL="${DEER_FLOW_BASE_URL:-http://localhost:2026}"
LANGGRAPH_URL="${BASE_URL}/api/langgraph"
GATEWAY_URL="${BASE_URL}/api"
TIMEOUT=60

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; }

# Wait for services to be ready
wait_for_services() {
    log_info "Waiting for services to be ready..."

    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if curl -s "${LANGGRAPH_URL}/info" > /dev/null 2>&1; then
            log_success "LangGraph API is ready"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done

    log_error "Services did not become ready in time"
    exit 1
}

# Test 1: Check LangGraph API health
test_langgraph_health() {
    log_info "Test 1: Checking LangGraph API health..."

    local response
    response=$(curl -s -w "\n%{http_code}" "${LANGGRAPH_URL}/info")

    if echo "$response" | grep -q "200"; then
        log_success "LangGraph API is healthy"
        return 0
    else
        log_error "LangGraph API health check failed"
        return 1
    fi
}

# Test 2: Create a thread
test_create_thread() {
    log_info "Test 2: Creating a thread..."

    local response
    local http_code

    response=$(curl -s -w "\n%{http_code}" -X POST "${LANGGRAPH_URL}/threads" \
        -H "Content-Type: application/json" \
        -d '{"metadata": {"test": true}}')

    http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "200" ]; then
        THREAD_ID=$(echo "$body" | grep -o '"thread_id":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$THREAD_ID" ]; then
            log_success "Thread created: $THREAD_ID"
            return 0
        fi
    fi

    log_error "Failed to create thread (HTTP $http_code)"
    return 1
}

# Test 3: Send a task to the thread
test_send_task() {
    log_info "Test 3: Sending task to thread..."

    if [ -z "$THREAD_ID" ]; then
        log_error "THREAD_ID is not set"
        return 1
    fi

    local response
    local http_code

    # Simple bash command to test sandbox execution
    local task='{"assistant_id": "lead_agent", "input": {"messages": [{"role": "user", "content": "Run this command: echo hello from sandbox"}]}, "stream_mode": ["values"]}'

    response=$(curl -s -w "\n%{http_code}" -X POST "${LANGGRAPH_URL}/threads/${THREAD_ID}/runs" \
        -H "Content-Type: application/json" \
        -d "$task")

    http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        log_success "Task sent successfully"
        return 0
    fi

    log_error "Failed to send task (HTTP $http_code)"
    return 1
}

# Test 4: Check thread state
test_get_thread() {
    log_info "Test 4: Getting thread state..."

    if [ -z "$THREAD_ID" ]; then
        log_error "THREAD_ID is not set"
        return 1
    fi

    local response
    local http_code

    response=$(curl -s -w "\n%{http_code}" "${LANGGRAPH_URL}/threads/${THREAD_ID}")

    http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "200" ]; then
        log_success "Thread state retrieved"
        return 0
    fi

    log_error "Failed to get thread (HTTP $http_code)"
    return 1
}

# Cleanup
cleanup() {
    log_info "Cleaning up..."

    if [ -n "$THREAD_ID" ]; then
        curl -s -X DELETE "${LANGGRAPH_URL}/threads/${THREAD_ID}" > /dev/null 2>&1 || true
        log_info "Deleted thread: $THREAD_ID"
    fi
}

# Main
main() {
    echo "=========================================="
    echo "  DeerFlow E2E Test: Sandbox Execution"
    echo "=========================================="
    echo ""

    local failed=0

    trap cleanup EXIT

    wait_for_services

    test_langgraph_health || failed=$((failed + 1))
    test_create_thread || failed=$((failed + 1))
    test_send_task || failed=$((failed + 1))
    test_get_thread || failed=$((failed + 1))

    echo ""
    echo "=========================================="
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
    else
        echo -e "${RED}$failed test(s) failed${NC}"
    fi
    echo "=========================================="

    return $failed
}

main "$@"
