#!/bin/sh
# Universal CI Verifier - Lightweight Shell Implementation
# Works on macOS, Linux, and any POSIX-compliant system
# Zero dependencies beyond standard Unix tools (sh, sed, grep)

# Don't exit on error - we handle errors ourselves
set +e

# Colors (with fallback for non-color terminals)
if [ -t 1 ]; then
    GREEN='\033[92m'
    RED='\033[91m'
    YELLOW='\033[93m'
    BLUE='\033[94m'
    RESET='\033[0m'
else
    GREEN=''
    RED=''
    YELLOW=''
    BLUE=''
    RESET=''
fi

CONFIG_FILE="universal-ci.config.json"
STAGE="test"

# Print usage
usage() {
    echo "Universal CI Verifier - Lightweight Shell Edition"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --config <path>    Path to config file (default: universal-ci.config.json)"
    echo "  --stage <stage>    Stage to run: test or release (default: test)"
    echo "  --help             Show this help message"
    exit 0
}

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --stage)
            STAGE="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            printf "${RED}Unknown option: $1${RESET}\n"
            usage
            ;;
    esac
done

# Find config file
find_config() {
    # Check provided/default path
    if [ -f "$CONFIG_FILE" ]; then
        echo "$CONFIG_FILE"
        return 0
    fi
    
    # Check parent directories
    if [ -f "../$CONFIG_FILE" ]; then
        echo "../$CONFIG_FILE"
        return 0
    fi
    if [ -f "../../$CONFIG_FILE" ]; then
        echo "../../$CONFIG_FILE"
        return 0
    fi
    if [ -f "../../../$CONFIG_FILE" ]; then
        echo "../../../$CONFIG_FILE"
        return 0
    fi
    
    # Check git root
    if command -v git >/dev/null 2>&1; then
        git_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
        if [ -n "$git_root" ] && [ -f "$git_root/$CONFIG_FILE" ]; then
            echo "$git_root/$CONFIG_FILE"
            return 0
        fi
    fi
    
    return 1
}

# Extract a JSON string value using sed (portable across macOS/Linux)
# Usage: get_json_value "key" "json_object"
get_json_value() {
    key="$1"
    json="$2"
    # Extract value after "key": "value" - handles simple cases
    echo "$json" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1
}

# Parse tasks from config file
# Outputs: name|working_directory|command for each matching task
parse_tasks() {
    config_path="$1"
    target_stage="$2"
    
    # Read config and flatten to single line
    config_content=$(cat "$config_path" | tr '\n' ' ' | tr '\r' ' ')
    
    # Extract tasks array content - everything between [ and ]
    tasks_content=$(echo "$config_content" | sed 's/.*"tasks"[[:space:]]*:[[:space:]]*\[//' | sed 's/\][[:space:]]*}[[:space:]]*//')
    
    # Split by },{ pattern to get individual tasks, then process each
    # Add newlines after each task object
    echo "$tasks_content" | sed 's/}[[:space:]]*,[[:space:]]*{/}|TASK_SEP|{/g' | tr '|' '\n' | grep -v "^TASK_SEP$" | while read -r task_json; do
        # Skip empty lines
        [ -z "$task_json" ] && continue
        
        # Extract fields using sed
        name=$(echo "$task_json" | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        dir=$(echo "$task_json" | sed -n 's/.*"working_directory"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        cmd=$(echo "$task_json" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        task_stage=$(echo "$task_json" | sed -n 's/.*"stage"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        
        # Default stage to "test" if not specified
        if [ -z "$task_stage" ]; then
            task_stage="test"
        fi
        
        # Output if stage matches and we have required fields
        if [ "$task_stage" = "$target_stage" ] && [ -n "$name" ] && [ -n "$cmd" ]; then
            # Use unit separator character as delimiter
            printf '%s\x1f%s\x1f%s\n' "$name" "$dir" "$cmd"
        fi
    done
}

# Run a single task
run_task() {
    name="$1"
    dir="$2"
    cmd="$3"
    
    echo "---------------------------------------------------"
    printf "${BLUE}🔍 Checking ${name}...${RESET}\n"
    echo "   📂 Path: ${dir}"
    echo "   🚀 Command: ${cmd}"
    
    # Check if directory exists
    if [ ! -d "$dir" ]; then
        printf "   ${YELLOW}⚠️  Skipped (Directory not found)${RESET}\n"
        return 0
    fi
    
    # Run command in subshell
    (cd "$dir" && eval "$cmd")
    result=$?
    
    if [ $result -eq 0 ]; then
        printf "   ${GREEN}✅ ${name} Passed${RESET}\n"
        return 0
    else
        printf "   ${RED}❌ ${name} FAILED${RESET}\n"
        return 1
    fi
}

# Main execution
main() {
    printf "${BLUE}🌐 Starting Universal CI Verification (Shell Edition)...${RESET}\n"
    
    # Detect environment
    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "   📍 Environment: GitHub Actions"
    elif [ -n "$CI" ]; then
        echo "   📍 Environment: CI Server"
    else
        echo "   📍 Environment: Local Shell"
    fi
    
    # Find config
    config_path=$(find_config)
    if [ -z "$config_path" ]; then
        printf "${RED}Error: Config file '${CONFIG_FILE}' not found.${RESET}\n"
        echo "Searched in: current directory, parent directories, and git root."
        exit 1
    fi
    
    echo "   📄 Config: ${config_path}"
    echo "---------------------------------------------------"
    stage_upper=$(echo "$STAGE" | tr '[:lower:]' '[:upper:]')
    printf "${BLUE}🛠  ${stage_upper} PHASE${RESET}\n"
    
    # Parse tasks into temp file to preserve across subshells
    tmp_tasks=$(mktemp)
    tmp_failures=$(mktemp)
    parse_tasks "$config_path" "$STAGE" > "$tmp_tasks"
    
    # Check if we have any tasks
    if [ ! -s "$tmp_tasks" ]; then
        printf "   ${YELLOW}No tasks found for stage: ${STAGE}${RESET}\n"
        rm -f "$tmp_tasks" "$tmp_failures"
        exit 0
    fi
    
    # Process each task
    while IFS=$(printf '\x1f') read -r name dir cmd; do
        if [ -n "$name" ]; then
            if ! run_task "$name" "$dir" "$cmd"; then
                echo "$name" >> "$tmp_failures"
            fi
        fi
    done < "$tmp_tasks"
    
    echo "---------------------------------------------------"
    printf "${BLUE}📊 SUMMARY${RESET}\n"
    
    # Check for failures
    if [ -s "$tmp_failures" ]; then
        printf "${RED}🚨 FAILURES DETECTED:${RESET}\n"
        while read -r fail_name; do
            echo "   - ${fail_name}"
        done < "$tmp_failures"
        rm -f "$tmp_tasks" "$tmp_failures"
        exit 1
    else
        printf "${GREEN}🎉 ALL SYSTEMS GO! Universal CI Passed.${RESET}\n"
        rm -f "$tmp_tasks" "$tmp_failures"
        exit 0
    fi
}

main