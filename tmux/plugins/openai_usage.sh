#!/usr/bin/env bash
# =============================================================================
# Plugin: openai_usage
# Description: Display OpenAI/Codex token usage and rate limits
# Dependencies: curl, jq (optional but recommended)
# =============================================================================

POWERKIT_ROOT="${POWERKIT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
. "${POWERKIT_ROOT}/src/contract/plugin_contract.sh"

# =============================================================================
# Plugin Contract: Metadata
# =============================================================================

plugin_get_metadata() {
    metadata_set "id" "openai_usage"
    metadata_set "name" "OpenAI Usage"
    metadata_set "description" "Display OpenAI/Codex token usage and rate limits"
}

# =============================================================================
# Plugin Contract: Dependencies
# =============================================================================

plugin_check_dependencies() {
    require_cmd "curl" || return 1
    require_cmd "jq" 1  # Optional but recommended for JSON parsing
    return 0
}

# =============================================================================
# Plugin Contract: Options
# =============================================================================

plugin_declare_options() {
    declare_option "token" "string" "" "OAuth token for OpenAI API (falls back to OPENAI_OAUTH_TOKEN env var)"
    declare_option "token_file" "string" "" "Path to file containing OAuth token (e.g., ~/.config/openai/token)"
    declare_option "account_id" "string" "" "Optional ChatGPT account ID for multi-account support"
    declare_option "show_plan" "bool" "false" "Show plan type (plus/pro) in output"
    declare_option "show_credits" "bool" "false" "Show credit balance in output"
    declare_option "warning_threshold" "number" "50" "Usage percentage that triggers warning state (50 = 50% used)"
    declare_option "error_threshold" "number" "80" "Usage percentage that triggers error state (80 = 80% used, 20% remaining)"
    declare_option "cache_ttl" "number" "300" "Cache duration in seconds (5 minutes)"
    declare_option "icon" "icon" $'\U0001F50B' "Battery icon for usage display"
    declare_option "format" "string" "compact" "Display format: compact, detailed, minimal"
}

# =============================================================================
# Internal Functions
# =============================================================================

_get_token() {
    # Priority 1: Environment variable
    if [[ -n "${OPENAI_OAUTH_TOKEN:-}" ]]; then
        printf '%s' "$OPENAI_OAUTH_TOKEN"
        return 0
    fi
    
    # Priority 2: tmux option (direct token)
    local token
    token=$(get_option "token")
    if [[ -n "$token" ]]; then
        printf '%s' "$token"
        return 0
    fi
    
    # Priority 3: Read from file
    local token_file
    token_file=$(get_option "token_file")
    if [[ -n "$token_file" && -f "$token_file" ]]; then
        token=$(cat "$token_file" 2>/dev/null | tr -d '[:space:]')
        if [[ -n "$token" ]]; then
            printf '%s' "$token"
            return 0
        fi
    fi
    
    return 1
}

_get_account_id() {
    local account_id
    account_id=$(get_option "account_id")
    [[ -n "$account_id" ]] && printf '%s' "$account_id"
}

_fetch_usage() {
    local token="$1"
    local account_id="$2"
    local timeout
    timeout=$(get_option "cache_ttl")
    timeout=$((timeout / 60))  # Convert to minutes for curl
    [[ $timeout -lt 1 ]] && timeout=5
    
    local url="https://chatgpt.com/backend-api/wham/usage"
    local headers=(
        -H "Authorization: Bearer ${token}"
        -H "User-Agent: CodexBar"
        -H "Accept: application/json"
    )
    
    if [[ -n "$account_id" ]]; then
        headers+=(-H "ChatGPT-Account-Id: ${account_id}")
    fi
    
    local response
    response=$(curl -s -m "$timeout" "${headers[@]}" "$url" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        return 1
    fi
    
    # Check for error response
    if echo "$response" | grep -q '"error"'; then
        return 1
    fi
    
    printf '%s' "$response"
}

_parse_usage() {
    local response="$1"
    local use_jq=false
    
    if has_cmd "jq"; then
        use_jq=true
    fi
    
    local primary_used secondary_used primary_reset secondary_reset plan_type credits
    
    if [[ "$use_jq" == "true" ]]; then
        primary_used=$(echo "$response" | jq -r '.rate_limit?.primary_window?.used_percent // 0')
        secondary_used=$(echo "$response" | jq -r '.rate_limit?.secondary_window?.used_percent // 0')
        primary_reset=$(echo "$response" | jq -r '.rate_limit?.primary_window?.reset_at // 0')
        secondary_reset=$(echo "$response" | jq -r '.rate_limit?.secondary_window?.reset_at // 0')
        plan_type=$(echo "$response" | jq -r '.plan_type // "unknown"')
        credits=$(echo "$response" | jq -r '.credits?.balance // "0"')
    else
        # Fallback to grep/sed parsing
        primary_used=$(echo "$response" | grep -o '"primary_window"[^}]*"used_percent":[0-9]*' | grep -o '[0-9]*' | tail -1)
        secondary_used=$(echo "$response" | grep -o '"secondary_window"[^}]*"used_percent":[0-9]*' | grep -o '[0-9]*' | tail -1)
        primary_reset=$(echo "$response" | grep -o '"primary_window"[^}]*"reset_at":[0-9]*' | grep -o '[0-9]*' | tail -1)
        secondary_reset=$(echo "$response" | grep -o '"secondary_window"[^}]*"reset_at":[0-9]*' | grep -o '[0-9]*' | tail -1)
        plan_type=$(echo "$response" | grep -o '"plan_type":"[^"]*"' | cut -d'"' -f4)
        credits=$(echo "$response" | grep -o '"balance":"[^"]*"' | cut -d'"' -f4)
        
        # Set defaults if empty
        primary_used=${primary_used:-0}
        secondary_used=${secondary_used:-0}
        primary_reset=${primary_reset:-0}
        secondary_reset=${secondary_reset:-0}
    fi
    
    printf '%s %s %s %s %s %s' "$primary_used" "$secondary_used" "$primary_reset" "$secondary_reset" "$plan_type" "$credits"
}

_format_reset_time() {
    local reset_timestamp="$1"
    local now
    now=$(date +%s)
    
    # reset_timestamp is in seconds, convert to milliseconds for comparison
    local reset_ms=$((reset_timestamp))
    local now_ms=$now
    
    local diff=$((reset_ms - now_ms))
    
    if [[ $diff -le 0 ]]; then
        printf 'now'
        return 0
    fi
    
    local minutes=$((diff / 60))
    local hours=$((minutes / 60))
    local days=$((hours / 24))
    
    if [[ $days -gt 0 ]]; then
        local remaining_hours=$((hours % 24))
        if [[ $remaining_hours -gt 0 ]]; then
            printf '%dd %dh' "$days" "$remaining_hours"
        else
            printf '%dd' "$days"
        fi
    elif [[ $hours -gt 0 ]]; then
        local remaining_minutes=$((minutes % 60))
        if [[ $remaining_minutes -gt 0 ]]; then
            printf '%dh %dm' "$hours" "$remaining_minutes"
        else
            printf '%dh' "$hours"
        fi
    else
        printf '%dm' "$minutes"
    fi
}

_format_window_label() {
    local window_seconds="$1"
    local hours=$((window_seconds / 3600))
    
    if [[ $hours -ge 24 ]]; then
        printf 'Day'
    else
        printf '%dh' "$hours"
    fi
}

# =============================================================================
# Plugin Contract: Content Type & Presence
# =============================================================================

plugin_get_content_type() { printf 'dynamic'; }
plugin_get_presence() { printf 'conditional'; }

# =============================================================================
# Plugin Contract: State & Health
# =============================================================================

plugin_get_state() {
    local has_token
    has_token=$(_get_token)
    [[ -z "$has_token" ]] && { printf 'inactive'; return 0; }
    
    local api_error
    api_error=$(plugin_data_get "api_error")
    [[ "$api_error" == "1" ]] && { printf 'degraded'; return 0; }
    
    local primary_used
    primary_used=$(plugin_data_get "primary_used")
    [[ -z "$primary_used" ]] && { printf 'failed'; return 0; }
    
    printf 'active'
}

plugin_get_health() {
    local primary_used
    primary_used=$(plugin_data_get "primary_used")
    [[ -z "$primary_used" ]] && { printf 'ok'; return 0; }
    
    local warning_threshold error_threshold
    warning_threshold=$(get_option "warning_threshold")
    error_threshold=$(get_option "error_threshold")
    
    # primary_used is the percentage USED, not remaining
    if [[ $primary_used -ge $error_threshold ]]; then
        printf 'error'
    elif [[ $primary_used -ge $warning_threshold ]]; then
        printf 'warning'
    else
        printf 'ok'
    fi
}

# =============================================================================
# Plugin Contract: Icon
# =============================================================================

plugin_get_icon() {
    get_option "icon"
}

# =============================================================================
# Plugin Contract: Data Collection
# =============================================================================

plugin_collect() {
    local token
    token=$(_get_token)
    
    if [[ -z "$token" ]]; then
        # No token configured - inactive state
        plugin_data_set "api_error" "0"
        return 0
    fi
    
    local account_id
    account_id=$(_get_account_id)
    
    local response
    response=$(_fetch_usage "$token" "$account_id")
    
    if [[ -z "$response" ]]; then
        # API error - will use stale data if available
        plugin_data_set "api_error" "1"
        return 1
    fi
    
    local parsed
    parsed=$(_parse_usage "$response")
    
    local primary_used secondary_used primary_reset secondary_reset plan_type credits
    read -r primary_used secondary_used primary_reset secondary_reset plan_type credits <<< "$parsed"
    
    # Store all data
    plugin_data_set "primary_used" "$primary_used"
    plugin_data_set "secondary_used" "$secondary_used"
    plugin_data_set "primary_reset" "$primary_reset"
    plugin_data_set "secondary_reset" "$secondary_reset"
    plugin_data_set "plan_type" "$plan_type"
    plugin_data_set "credits" "$credits"
    plugin_data_set "api_error" "0"
    
    return 0
}

# =============================================================================
# Plugin Contract: Rendering
# =============================================================================

plugin_render() {
    local format
    format=$(get_option "format")
    
    local primary_used secondary_used primary_reset secondary_reset plan_type credits
    primary_used=$(plugin_data_get "primary_used")
    secondary_used=$(plugin_data_get "secondary_used")
    primary_reset=$(plugin_data_get "primary_reset")
    secondary_reset=$(plugin_data_get "secondary_reset")
    plan_type=$(plugin_data_get "plan_type")
    credits=$(plugin_data_get "credits")
    
    # Check if we have data
    [[ -z "$primary_used" ]] && return 0
    
    local primary_remaining=$((100 - primary_used))
    local secondary_remaining=$((100 - secondary_used))
    
    local primary_reset_formatted
    primary_reset_formatted=$(_format_reset_time "$primary_reset")
    
    local show_plan show_credits
    show_plan=$(get_option "show_plan")
    show_credits=$(get_option "show_credits")
    
    case "$format" in
        "minimal")
            # Minimal: "41%⏱2h58m" (lowest remaining % and shortest reset)
            local lowest_remaining=$primary_remaining
            local shortest_reset=$primary_reset_formatted
            
            if [[ $secondary_remaining -lt $lowest_remaining ]]; then
                lowest_remaining=$secondary_remaining
            fi
            
            printf 'O:%d%%⏱%s' "$lowest_remaining" "$shortest_reset"
            ;;
            
        "detailed")
            # Detailed: "Codex (plus) · 5h: 41% left · resets 2h 58m · Day: 45% left · resets 5d 19h"
            local output=""
            
            output="O:"
            if [[ "$show_plan" == "true" && -n "$plan_type" ]]; then
                output="${output}Codex ($plan_type)"
                [[ "$show_credits" == "true" && -n "$credits" ]] && output="$output \$$credits"
                output="$output · "
            fi
            
            local primary_label secondary_label secondary_reset_formatted
            primary_label=$(_format_window_label "10800")  # Default 3h
            secondary_label=$(_format_window_label "86400")  # Default 24h
            secondary_reset_formatted=$(_format_reset_time "$secondary_reset")
            
            output="${output}${primary_label}: ${primary_remaining}% left · resets ${primary_reset_formatted}"
            output="${output} · ${secondary_label}: ${secondary_remaining}% left · resets ${secondary_reset_formatted}"
            
            printf '%s' "$output"
            ;;
            
        "compact"|*)
            # Compact: "41% · 2h 58m" (lowest remaining % and shortest reset)
            local lowest_remaining=$primary_remaining
            local shortest_reset=$primary_reset_formatted
            local window_label
            window_label=$(_format_window_label "10800")
            
            # If secondary has less remaining, use that
            if [[ $secondary_remaining -lt $lowest_remaining ]]; then
                lowest_remaining=$secondary_remaining
                shortest_reset=$(_format_reset_time "$secondary_reset")
                window_label=$(_format_window_label "86400")
            fi
            
            local output="O:${lowest_remaining}%"
            
            if [[ "$show_plan" == "true" && -n "$plan_type" ]]; then
                output="${output} ($plan_type)"
            fi
            
            output="${output} · ${shortest_reset}"
            printf '%s' "$output"
            ;;
    esac
}
