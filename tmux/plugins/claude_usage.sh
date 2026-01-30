#!/usr/bin/env bash
# =============================================================================
# Plugin: claude_usage
# Description: Display Anthropic Claude token usage and rate limits
# Dependencies: curl, jq (optional but recommended)
# =============================================================================

POWERKIT_ROOT="${POWERKIT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
. "${POWERKIT_ROOT}/src/contract/plugin_contract.sh"

# =============================================================================
# Plugin Contract: Metadata
# =============================================================================

plugin_get_metadata() {
    metadata_set "id" "claude_usage"
    metadata_set "name" "Claude Usage"
    metadata_set "description" "Display Anthropic Claude token usage and rate limits"
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
    declare_option "token" "string" "" "OAuth token for Anthropic API (falls back to ANTHROPIC_OAUTH_TOKEN env var)"
    declare_option "token_file" "string" "" "Path to file containing OAuth token (e.g., ~/.config/anthropic/token)"
    declare_option "warning_threshold" "number" "50" "Usage percentage that triggers warning state (50 = 50% used)"
    declare_option "error_threshold" "number" "80" "Usage percentage that triggers error state (80 = 80% used, 20% remaining)"
    declare_option "cache_ttl" "number" "300" "Cache duration in seconds (5 minutes)"
    declare_option "icon" "icon" $'\U0000F6A9' "Robot icon for Claude display"
    declare_option "format" "string" "compact" "Display format: compact, detailed, minimal"
    declare_option "show_model_breakdown" "bool" "false" "Show model-specific usage (Sonnet/Opus)"
}

# =============================================================================
# Internal Functions
# =============================================================================

_get_token() {
    # Priority 1: Environment variable
    if [[ -n "${ANTHROPIC_OAUTH_TOKEN:-}" ]]; then
        printf '%s' "$ANTHROPIC_OAUTH_TOKEN"
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

_fetch_usage() {
    local token="$1"
    local timeout
    timeout=$(get_option "cache_ttl")
    timeout=$((timeout / 60))  # Convert to minutes for curl
    [[ $timeout -lt 1 ]] && timeout=5
    
    local url="https://api.anthropic.com/api/oauth/usage"
    local headers=(
        -H "Authorization: Bearer ${token}"
        -H "User-Agent: openclaw"
        -H "Accept: application/json"
        -H "anthropic-version: 2023-06-01"
        -H "anthropic-beta: oauth-2025-04-20"
    )
    
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
    
    local five_hour_util seven_day_util five_hour_reset seven_day_reset sonnet_util opus_util
    
    if [[ "$use_jq" == "true" ]]; then
        five_hour_util=$(echo "$response" | jq -r '.five_hour?.utilization // 0')
        seven_day_util=$(echo "$response" | jq -r '.seven_day?.utilization // 0')
        five_hour_reset=$(echo "$response" | jq -r '.five_hour?.resets_at // ""')
        seven_day_reset=$(echo "$response" | jq -r '.seven_day?.resets_at // ""')
        sonnet_util=$(echo "$response" | jq -r '.seven_day_sonnet?.utilization // 0')
        opus_util=$(echo "$response" | jq -r '.seven_day_opus?.utilization // 0')
    else
        # Fallback to grep/sed parsing
        five_hour_util=$(echo "$response" | grep -o '"five_hour"[^}]*"utilization":[0-9.]*' | grep -o '[0-9.]*' | tail -1)
        seven_day_util=$(echo "$response" | grep -o '"seven_day"[^}]*"utilization":[0-9.]*' | grep -o '[0-9.]*' | tail -1)
        five_hour_reset=$(echo "$response" | grep -o '"five_hour"[^}]*"resets_at":"[^"]*"' | cut -d'"' -f8)
        seven_day_reset=$(echo "$response" | grep -o '"seven_day"[^}]*"resets_at":"[^"]*"' | cut -d'"' -f8)
        sonnet_util=$(echo "$response" | grep -o '"seven_day_sonnet"[^}]*"utilization":[0-9.]*' | grep -o '[0-9.]*' | tail -1)
        opus_util=$(echo "$response" | grep -o '"seven_day_opus"[^}]*"utilization":[0-9.]*' | grep -o '[0-9.]*' | tail -1)
        
        # Set defaults if empty
        five_hour_util=${five_hour_util:-0}
        seven_day_util=${seven_day_util:-0}
        sonnet_util=${sonnet_util:-0}
        opus_util=${opus_util:-0}
    fi
    
    # Convert utilization to percentage (0.45 -> 45)
    five_hour_util=$(echo "$five_hour_util * 100" | bc 2>/dev/null || printf '%.0f' "$(echo "$five_hour_util * 100" | cut -d. -f1)")
    seven_day_util=$(echo "$seven_day_util * 100" | bc 2>/dev/null || printf '%.0f' "$(echo "$seven_day_util * 100" | cut -d. -f1)")
    sonnet_util=$(echo "$sonnet_util * 100" | bc 2>/dev/null || printf '%.0f' "$(echo "$sonnet_util * 100" | cut -d. -f1)")
    opus_util=$(echo "$opus_util * 100" | bc 2>/dev/null || printf '%.0f' "$(echo "$opus_util * 100" | cut -d. -f1)")
    
    printf '%s %s %s %s %s %s' "$five_hour_util" "$seven_day_util" "$five_hour_reset" "$seven_day_reset" "$sonnet_util" "$opus_util"
}

_format_reset_time() {
    local reset_iso="$1"
    [[ -z "$reset_iso" ]] && return 0
    
    # Parse ISO 8601 timestamp
    local reset_epoch
    if has_cmd "date"; then
        # Try GNU date first
        reset_epoch=$(date -d "$reset_iso" +%s 2>/dev/null)
        # If that fails, try BSD date (macOS)
        if [[ -z "$reset_epoch" ]]; then
            reset_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$reset_iso" +%s 2>/dev/null)
        fi
    fi
    
    [[ -z "$reset_epoch" ]] && return 0
    
    local now
    now=$(date +%s)
    
    local diff=$((reset_epoch - now))
    
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
    
    local five_hour_util
    five_hour_util=$(plugin_data_get "five_hour_util")
    [[ -z "$five_hour_util" ]] && { printf 'failed'; return 0; }
    
    printf 'active'
}

plugin_get_health() {
    local five_hour_util
    five_hour_util=$(plugin_data_get "five_hour_util")
    [[ -z "$five_hour_util" ]] && { printf 'ok'; return 0; }
    
    local warning_threshold error_threshold
    warning_threshold=$(get_option "warning_threshold")
    error_threshold=$(get_option "error_threshold")
    
    # five_hour_util is the percentage USED, not remaining
    if [[ $five_hour_util -ge $error_threshold ]]; then
        printf 'error'
    elif [[ $five_hour_util -ge $warning_threshold ]]; then
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
    
    local response
    response=$(_fetch_usage "$token")
    
    if [[ -z "$response" ]]; then
        # API error - will use stale data if available
        plugin_data_set "api_error" "1"
        return 1
    fi
    
    local parsed
    parsed=$(_parse_usage "$response")
    
    local five_hour_util seven_day_util five_hour_reset seven_day_reset sonnet_util opus_util
    read -r five_hour_util seven_day_util five_hour_reset seven_day_reset sonnet_util opus_util <<< "$parsed"
    
    # Store all data
    plugin_data_set "five_hour_util" "$five_hour_util"
    plugin_data_set "seven_day_util" "$seven_day_util"
    plugin_data_set "five_hour_reset" "$five_hour_reset"
    plugin_data_set "seven_day_reset" "$seven_day_reset"
    plugin_data_set "sonnet_util" "$sonnet_util"
    plugin_data_set "opus_util" "$opus_util"
    plugin_data_set "api_error" "0"
    
    return 0
}

# =============================================================================
# Plugin Contract: Rendering
# =============================================================================

plugin_render() {
    local format
    format=$(get_option "format")
    
    local five_hour_util seven_day_util five_hour_reset seven_day_reset sonnet_util opus_util
    five_hour_util=$(plugin_data_get "five_hour_util")
    seven_day_util=$(plugin_data_get "seven_day_util")
    five_hour_reset=$(plugin_data_get "five_hour_reset")
    seven_day_reset=$(plugin_data_get "seven_day_reset")
    sonnet_util=$(plugin_data_get "sonnet_util")
    opus_util=$(plugin_data_get "opus_util")
    
    # Check if we have data
    [[ -z "$five_hour_util" ]] && return 0
    
    local five_hour_remaining=$((100 - five_hour_util))
    local seven_day_remaining=$((100 - seven_day_util))
    
    local five_hour_reset_formatted seven_day_reset_formatted
    five_hour_reset_formatted=$(_format_reset_time "$five_hour_reset")
    seven_day_reset_formatted=$(_format_reset_time "$seven_day_reset")
    
    local show_model_breakdown
    show_model_breakdown=$(get_option "show_model_breakdown")
    
    case "$format" in
        "minimal")
            # Minimal: "41%⏱2h30m" (lowest remaining % and shortest reset)
            local lowest_remaining=$five_hour_remaining
            local shortest_reset=$five_hour_reset_formatted
            
            if [[ $seven_day_remaining -lt $lowest_remaining ]]; then
                lowest_remaining=$seven_day_remaining
                shortest_reset=$seven_day_reset_formatted
            fi
            
            printf 'C:%d%%⏱%s' "$lowest_remaining" "$shortest_reset"
            ;;
            
        "detailed")
            # Detailed: "5h: 41% left · resets 2h 30m · Week: 70% left · resets 5d 12h"
            local output="C:"
            
            output="${output}5h: ${five_hour_remaining}% left · resets ${five_hour_reset_formatted}"
            output="${output} · Week: ${seven_day_remaining}% left · resets ${seven_day_reset_formatted}"
            
            if [[ "$show_model_breakdown" == "true" ]]; then
                local sonnet_remaining=$((100 - sonnet_util))
                local opus_remaining=$((100 - opus_util))
                output="${output} · Sonnet: ${sonnet_remaining}% · Opus: ${opus_remaining}%"
            fi
            
            printf '%s' "$output"
            ;;
            
        "compact"|*)
            # Compact: "41% · 2h 30m" (lowest remaining % and shortest reset)
            local lowest_remaining=$five_hour_remaining
            local shortest_reset=$five_hour_reset_formatted
            local window_label="5h"
            
            # If 7-day has less remaining, use that
            if [[ $seven_day_remaining -lt $lowest_remaining ]]; then
                lowest_remaining=$seven_day_remaining
                shortest_reset=$seven_day_reset_formatted
                window_label="Week"
            fi
            
            local output="C:${lowest_remaining}%"
            output="${output} · ${shortest_reset}"
            printf '%s' "$output"
            ;;
    esac
}
