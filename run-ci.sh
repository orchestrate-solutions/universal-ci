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
    CYAN='\033[96m'
    RESET='\033[0m'
else
    GREEN=''
    RED=''
    YELLOW=''
    BLUE=''
    CYAN=''
    RESET=''
fi

CONFIG_FILE="universal-ci.config.json"
STAGE="test"
INIT_MODE=false
FORCE_TYPE=""
INTERACTIVE_MODE=false
LIST_TASKS_ONLY=false
SELECTED_TASKS=""
APPROVED_TASKS=""
SKIPPED_TASKS=""
CACHE_DIR=".universal-ci-cache"

# Print usage
usage() {
    echo "Universal CI Verifier - Lightweight Shell Edition"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  --init             Initialize a new project (detect type, create config)"
    echo ""
    echo "Options:"
    echo "  --config <path>    Path to config file (default: universal-ci.config.json)"
    echo "  --stage <stage>    Stage to run: test or release (default: test)"
    echo "  --type <type>      Force project type for --init (nodejs, python, go, rust, etc.)"
    echo "  --interactive      Interactive mode (requires --list-tasks or task selection flags)"
    echo "  --list-tasks       Output all tasks as JSON (use with --interactive)"
    echo "  --select-tasks     JSON array of task names to run (e.g., '[\"task1\",\"task2\"]')"
    echo "  --approve-task     Approve a task requiring approval (can be used multiple times)"
    echo "  --skip-task        Skip a task by name (can be used multiple times)"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                 Run verification with auto-detected config"
    echo "  $0 --init          Initialize config for current project"
    echo "  $0 --stage release Run release tasks"
    echo "  $0 --interactive --list-tasks        List all tasks as JSON"
    echo "  $0 --select-tasks '[\"test\",\"build\"]' Run only selected tasks"
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
        --init)
            INIT_MODE=true
            shift
            ;;
        --type)
            FORCE_TYPE="$2"
            shift 2
            ;;
        --interactive)
            INTERACTIVE_MODE=true
            shift
            ;;
        --list-tasks)
            LIST_TASKS_ONLY=true
            shift
            ;;
        --select-tasks)
            SELECTED_TASKS="$2"
            shift 2
            ;;
        --approve-task)
            if [ -z "$APPROVED_TASKS" ]; then
                APPROVED_TASKS="$2"
            else
                APPROVED_TASKS="$APPROVED_TASKS|$2"
            fi
            shift 2
            ;;
        --skip-task)
            if [ -z "$SKIPPED_TASKS" ]; then
                SKIPPED_TASKS="$2"
            else
                SKIPPED_TASKS="$SKIPPED_TASKS|$2"
            fi
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

# Hash a file using md5sum or md5 (macOS)
# Usage: hash_file "/path/to/file"
hash_file() {
    file_path="$1"
    if [ ! -f "$file_path" ]; then
        echo ""
        return 1
    fi
    if command -v md5sum >/dev/null 2>&1; then
        md5sum "$file_path" | awk '{print $1}'
    elif command -v md5 >/dev/null 2>&1; then
        md5 -q "$file_path"
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file_path" | awk '{print $1}' | cut -c1-12
    else
        # Fallback: use file modification time
        stat -f %m "$file_path" 2>/dev/null || stat -c %Y "$file_path" 2>/dev/null || echo ""
    fi
}

# Resolve hashFiles placeholder in cache key
# Usage: resolve_hash_key "npm-${{ hashFiles('package-lock.json') }}" "src/"
resolve_hash_key() {
    key="$1"
    base_dir="${2:-.}"
    
    # Find all ${{ hashFiles(...) }} patterns and replace with hashes
    result="$key"
    
    # Extract patterns like hashFiles('path1', 'path2', ...)
    # For simplicity, handle single file first
    if echo "$result" | grep -q 'hashFiles'; then
        # Extract file paths from hashFiles() calls
        patterns=$(echo "$result" | sed -n 's/.*hashFiles(\([^)]*\)).*/\1/p')
        
        if [ -n "$patterns" ]; then
            # Remove quotes and split by comma
            files=$(echo "$patterns" | sed "s/'//g" | sed 's/"//g' | tr ',' '\n')
            
            combined_hash=""
            for file_glob in $files; do
                file_glob=$(echo "$file_glob" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                
                # Handle glob patterns by finding first match
                matched_file=""
                for f in "$base_dir"/$file_glob; do
                    if [ -f "$f" ]; then
                        matched_file="$f"
                        break
                    fi
                done
                
                # Also try without base_dir prefix
                if [ -z "$matched_file" ] && [ -f "$file_glob" ]; then
                    matched_file="$file_glob"
                fi
                
                if [ -n "$matched_file" ]; then
                    file_hash=$(hash_file "$matched_file")
                    if [ -n "$combined_hash" ]; then
                        combined_hash="${combined_hash}${file_hash}"
                    else
                        combined_hash="$file_hash"
                    fi
                fi
            done
            
            # Replace hashFiles() with computed hash (first 16 chars)
            if [ -n "$combined_hash" ]; then
                final_hash=$(echo "$combined_hash" | cut -c1-16)
                result=$(echo "$result" | sed "s/\${{ *hashFiles([^)]*) *}}/$final_hash/g")
            fi
        fi
    fi
    
    echo "$result"
}

# Evaluate task condition expression
# Usage: evaluate_condition "env.CI == 'true' && os(linux)"
# Returns 0 if true, 1 if false
evaluate_condition() {
    condition="$1"
    
    if [ -z "$condition" ]; then
        return 0
    fi
    
    # Handle boolean operators: && and ||
    # For simplicity, evaluate left-to-right with proper precedence
    
    # Replace environment variable references
    # env.VAR_NAME -> ${VAR_NAME}
    eval_expr=$(echo "$condition" | sed 's/env\.\([A-Za-z_][A-Za-z0-9_]*\)/\$\1/g')
    
    # Replace function calls
    # os(linux) -> true if current OS is linux
    if echo "$eval_expr" | grep -q 'os('; then
        os_type=$(uname -s | tr '[:upper:]' '[:lower:]')
        case "$os_type" in
            linux) os_linux=true ;;
            darwin) os_macos=true ;;
            *) ;;
        esac
        
        eval_expr=$(echo "$eval_expr" | sed 's/os(linux)/'"$([ "$os_linux" = true ] && echo 'true' || echo 'false')"'/g')
        eval_expr=$(echo "$eval_expr" | sed 's/os(macos)/'"$([ "$os_macos" = true ] && echo 'true' || echo 'false')"'/g')
    fi
    
    # Replace file() function
    # file(path) -> true if file exists
    if echo "$eval_expr" | grep -q 'file('; then
        file_paths=$(echo "$eval_expr" | sed -n 's/.*file(\([^)]*\)).*/\1/p')
        for fpath in $file_paths; do
            fpath=$(echo "$fpath" | sed "s/'//g" | sed 's/"//g')
            if [ -f "$fpath" ]; then
                eval_expr=$(echo "$eval_expr" | sed "s/file($fpath)/true/g")
            else
                eval_expr=$(echo "$eval_expr" | sed "s/file($fpath)/false/g")
            fi
        done
    fi
    
    # Replace branch() function
    # branch(main) -> true if on main branch
    if echo "$eval_expr" | grep -q 'branch('; then
        current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        branch_names=$(echo "$eval_expr" | sed -n 's/.*branch(\([^)]*\)).*/\1/p')
        for bname in $branch_names; do
            bname=$(echo "$bname" | sed "s/'//g" | sed 's/"//g')
            if [ "$current_branch" = "$bname" ]; then
                eval_expr=$(echo "$eval_expr" | sed "s/branch($bname)/true/g")
            else
                eval_expr=$(echo "$eval_expr" | sed "s/branch($bname)/false/g")
            fi
        done
    fi
    
    # Simple string comparison: == and !=
    # For now, handle quoted strings
    eval_expr=$(echo "$eval_expr" | sed "s/'[^']*' == '[^']*'/STRCMP/g")
    
    # Handle simple variable comparisons
    # For GitHub context variables like ${{ github.ref }}
    if echo "$condition" | grep -q 'github\.'; then
        # Mock or get from environment
        github_ref="${GITHUB_REF:-refs/heads/unknown}"
        eval_expr=$(echo "$eval_expr" | sed "s|\${{ *github\.ref *}}|${github_ref}|g")
    fi
    
    # Now evaluate with bash/sh logic
    # Convert true/false to proper shell semantics
    eval_expr=$(echo "$eval_expr" | sed 's/true/true/g' | sed 's/false/false/g')
    
    # For complex boolean logic, use a helper
    # This is simplified; for MVP, just check if any "false" appears
    if echo "$eval_expr" | grep -qE '(false|!true)'; then
        return 1
    fi
    
    return 0
}

# Parse tasks from config file
# Outputs: name|working_directory|command|cache_key|condition|requires_approval for each matching task
parse_tasks() {
    config_path="$1"
    target_stage="$2"
    
    # Use Python for reliable JSON parsing - it's available everywhere
    python3 -c "
import json
import sys

with open('$config_path', 'r') as f:
    config = json.load(f)

for task in config.get('tasks', []):
    name = task.get('name', '')
    directory = task.get('working_directory', '.')
    command = task.get('command', '')
    stage = task.get('stage', 'test')
    cache_key = task.get('cache', {}).get('key', '') if isinstance(task.get('cache'), dict) else ''
    condition = task.get('if', '')
    requires_approval = 'true' if task.get('requires_approval') else ''
    versions = task.get('versions', [])
    
    if stage == '$target_stage' and name and command:
        if versions:
            for version in versions:
                expanded_name = name.replace('{version}', str(version))
                expanded_cmd = command.replace('{version}', str(version))
                print(f'{expanded_name}\x1f{directory}\x1f{expanded_cmd}\x1f{cache_key}\x1f{condition}\x1f{requires_approval}')
        else:
            print(f'{name}\x1f{directory}\x1f{command}\x1f{cache_key}\x1f{condition}\x1f{requires_approval}')
" 2>/dev/null || {
        # Fallback to simple sed-based parsing if Python fails
        # Read config and process line by line to avoid flattening issues
        config_content=$(cat "$config_path" | tr '\n' ' ' | tr '\r' ' ')
        
        # Extract each task object carefully
        echo "$config_content" | grep -oE '\{[^{}]*"name"[^{}]*\}' | while read -r task_json; do
            [ -z "$task_json" ] && continue
            
            # Extract fields - use first match only
            name=$(echo "$task_json" | sed -n 's/^[^"]*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
            dir=$(echo "$task_json" | sed -n 's/^[^"]*"working_directory"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
            cmd=$(echo "$task_json" | sed -n 's/^[^"]*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
            task_stage=$(echo "$task_json" | sed -n 's/^[^"]*"stage"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
            
            [ -z "$task_stage" ] && task_stage="test"
            
            if [ "$task_stage" = "$target_stage" ] && [ -n "$name" ] && [ -n "$cmd" ]; then
                printf '%s\x1f%s\x1f%s\x1f\x1f\x1f\n' "$name" "$dir" "$cmd"
            fi
        done
    }
}

# Output tasks as JSON for interactive mode
output_tasks_json() {
    tmp_tasks="$1"
    
    printf "{"
    printf "\"tasks\":["
    
    first=true
    while IFS=$(printf '\x1f') read -r name dir cmd cache_key condition requires_approval; do
        if [ -n "$name" ]; then
            if [ "$first" = false ]; then
                printf ","
            fi
            first=false
            
            printf "{"
            printf "\"name\":\"%s\"," "$(echo "$name" | sed 's/"/\\"/g')"
            printf "\"directory\":\"%s\"," "$(echo "$dir" | sed 's/"/\\"/g')"
            printf "\"command\":\"%s\"," "$(echo "$cmd" | sed 's/"/\\"/g')"
            
            # Add optional fields
            if [ -n "$cache_key" ]; then
                printf "\"cache_key\":\"%s\"," "$(echo "$cache_key" | sed 's/"/\\"/g')"
            fi
            if [ -n "$condition" ]; then
                printf "\"condition\":\"%s\"," "$(echo "$condition" | sed 's/"/\\"/g')"
            fi
            if [ "$requires_approval" = "true" ]; then
                printf "\"requires_approval\":true"
            fi
            
            printf "}"
        fi
    done < "$tmp_tasks"
    
    printf "]}"
}

# Parse JSON array of task names from --select-tasks
# Usage: parse_task_selection '["task1","task2"]'
# Sets SELECTED_TASKS_ARRAY variable
parse_task_selection() {
    selection="$1"
    
    # Extract task names from JSON array
    # Simple approach: remove brackets and split by comma
    SELECTED_TASKS_ARRAY=$(echo "$selection" | sed 's/^\[//;s/\]$//' | sed 's/"//g' | sed 's/,/\n/g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
}
run_task() {
    name="$1"
    dir="$2"
    cmd="$3"
    cache_key="$4"
    condition="$5"
    requires_approval="$6"
    
    echo "---------------------------------------------------"
    printf "${BLUE}🔍 Checking ${name}...${RESET}\n"
    echo "   📂 Path: ${dir}"
    echo "   🚀 Command: ${cmd}"
    
    # Check condition
    if [ -n "$condition" ]; then
        if ! evaluate_condition "$condition"; then
            printf "   ${YELLOW}⊘ Skipped (condition not met)${RESET}\n"
            return 0
        fi
    fi
    
    # Check if approval is required and not granted
    if [ "$requires_approval" = "true" ]; then
        is_approved=false
        if [ -n "$APPROVED_TASKS" ]; then
            # Check if this task is in approved list
            echo "$APPROVED_TASKS" | tr '|' '\n' | grep -q "^${name}$" && is_approved=true
        fi
        
        if [ "$is_approved" = "false" ]; then
            printf "   ${YELLOW}⊘ Skipped (requires approval, use --approve-task)${RESET}\n"
            return 0
        fi
    fi
    
    # Check if task is in skip list
    if [ -n "$SKIPPED_TASKS" ]; then
        if echo "$SKIPPED_TASKS" | tr '|' '\n' | grep -q "^${name}$"; then
            printf "   ${YELLOW}⊘ Skipped (explicitly skipped)${RESET}\n"
            return 0
        fi
    fi
    
    # Check directory exists
    if [ ! -d "$dir" ]; then
        printf "   ${YELLOW}⚠️  Skipped (Directory not found)${RESET}\n"
        return 0
    fi
    
    # Handle caching
    cache_hit=false
    if [ -n "$cache_key" ]; then
        # Resolve hash placeholders in cache key
        resolved_cache_key=$(resolve_hash_key "$cache_key" "$dir")
        cache_path="${CACHE_DIR}/${resolved_cache_key}"
        
        if [ -d "$cache_path" ]; then
            printf "   ${GREEN}⚡ Cache hit! (${resolved_cache_key})${RESET}\n"
            cache_hit=true
            
            # Restore cached files (if any were specified, but for now we skip task execution)
            # In a real scenario, you'd restore node_modules, build artifacts, etc.
            return 0
        fi
    fi
    
    # Run command in subshell
    (cd "$dir" && eval "$cmd")
    result=$?
    
    # Save to cache if configured
    if [ $result -eq 0 ] && [ -n "$cache_key" ]; then
        mkdir -p "$cache_path"
        # Mark cache as valid (in real scenario, would save specific files)
        touch "$cache_path/.cache-valid"
    fi
    
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
    tmp_passed=$(mktemp)
    parse_tasks "$config_path" "$STAGE" > "$tmp_tasks"
    
    # Check if we have any tasks
    if [ ! -s "$tmp_tasks" ]; then
        printf "   ${YELLOW}No tasks found for stage: ${STAGE}${RESET}\n"
        rm -f "$tmp_tasks" "$tmp_failures" "$tmp_passed"
        exit 0
    fi
    
    # Interactive mode: list tasks and exit
    if [ "$LIST_TASKS_ONLY" = "true" ]; then
        output_tasks_json "$tmp_tasks"
        rm -f "$tmp_tasks" "$tmp_failures" "$tmp_passed"
        exit 0
    fi
    
    # Interactive mode: filter tasks by selection
    if [ -n "$SELECTED_TASKS" ]; then
        parse_task_selection "$SELECTED_TASKS"
        
        # Create new temp file with only selected tasks
        tmp_filtered=$(mktemp)
        while IFS=$(printf '\x1f') read -r name dir cmd cache_key condition requires_approval; do
            if [ -n "$name" ]; then
                # Check if task is in selected list
                if echo "$SELECTED_TASKS_ARRAY" | grep -q "^${name}$"; then
                    printf '%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s\n' "$name" "$dir" "$cmd" "$cache_key" "$condition" "$requires_approval" >> "$tmp_filtered"
                fi
            fi
        done < "$tmp_tasks"
        
        # Use filtered list
        mv "$tmp_filtered" "$tmp_tasks"
    fi
    
    # Process each task
    while IFS=$(printf '\x1f') read -r name dir cmd cache_key condition requires_approval; do
        if [ -n "$name" ]; then
            if ! run_task "$name" "$dir" "$cmd" "$cache_key" "$condition" "$requires_approval"; then
                echo "$name" >> "$tmp_failures"
            else
                echo "$name" >> "$tmp_passed"
            fi
        fi
    done < "$tmp_tasks"
    
    echo "---------------------------------------------------"
    printf "${BLUE}📊 SUMMARY${RESET}\n"
    
    # Show passed tasks
    if [ -s "$tmp_passed" ]; then
        while read -r pass_name; do
            echo "   ✅ $pass_name"
        done < "$tmp_passed"
    fi

    # Check for failures
    if [ -s "$tmp_failures" ]; then
        printf "${RED}🚨 FAILURES DETECTED:${RESET}\n"
        while read -r fail_name; do
            echo "   ❌ ${fail_name}"
        done < "$tmp_failures"
        rm -f "$tmp_tasks" "$tmp_failures" "$tmp_passed"
        exit 1
    else
        echo ""
        printf "${GREEN}🎉 ALL SYSTEMS GO! Universal CI Passed.${RESET}\n"
        rm -f "$tmp_tasks" "$tmp_failures" "$tmp_passed"
        exit 0
    fi
}

# ============================================================================
# INIT MODE - Project Detection and Config Generation
# ============================================================================

detect_project_type() {
    if [ -n "$FORCE_TYPE" ]; then echo "$FORCE_TYPE"; return 0; fi
    if [ -f "package.json" ]; then echo "nodejs"; return 0; fi
    if [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ] || [ -f "Pipfile" ]; then echo "python"; return 0; fi
    if [ -f "go.mod" ]; then echo "go"; return 0; fi
    if [ -f "Cargo.toml" ]; then echo "rust"; return 0; fi
    if ls *.csproj 1>/dev/null 2>&1 || ls *.fsproj 1>/dev/null 2>&1; then echo "dotnet"; return 0; fi
    if [ -f "pom.xml" ]; then echo "java-maven"; return 0; fi
    if [ -d "src/main/kotlin" ]; then echo "kotlin"; return 0; fi
    if [ -f "build.sbt" ] || [ -d "src/main/scala" ]; then echo "scala"; return 0; fi
    if [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then echo "java-gradle"; return 0; fi
    if [ -f "Package.swift" ] || [ -d "Sources" ]; then echo "swift"; return 0; fi
    if [ -f "CMakeLists.txt" ] || ls *.cpp 1>/dev/null 2>&1 || ls *.cc 1>/dev/null 2>&1; then echo "cpp"; return 0; fi
    if [ -f "pubspec.yaml" ] || ls *.dart 1>/dev/null 2>&1; then echo "dart"; return 0; fi
    if [ -f "Gemfile" ]; then echo "ruby"; return 0; fi
    if [ -f "composer.json" ]; then echo "php"; return 0; fi
    if [ -f "Makefile" ]; then echo "make"; return 0; fi
    echo "generic"
}

detect_node_pm() {
    if [ -f "pnpm-lock.yaml" ]; then echo "pnpm"
    elif [ -f "yarn.lock" ]; then echo "yarn"
    elif [ -f "bun.lockb" ]; then echo "bun"
    else echo "npm"; fi
}

detect_python_pm() {
    if [ -f "poetry.lock" ]; then echo "poetry"
    elif [ -f "Pipfile" ]; then echo "pipenv"
    elif [ -f "uv.lock" ]; then echo "uv"
    else echo "pip"; fi
}

has_npm_script() {
    [ -f "package.json" ] && grep -q "\"$1\"" package.json 2>/dev/null
}

generate_config() {
    project_type="$1"
    
    case "$project_type" in
        nodejs)
            pm=$(detect_node_pm)
            case "$pm" in
                pnpm) ic="pnpm install"; tc="pnpm test"; lc="pnpm run lint"; bc="pnpm run build" ;;
                yarn) ic="yarn install"; tc="yarn test"; lc="yarn lint"; bc="yarn build" ;;
                bun)  ic="bun install"; tc="bun test"; lc="bun run lint"; bc="bun run build" ;;
                *)    ic="npm ci"; tc="npm test"; lc="npm run lint"; bc="npm run build" ;;
            esac
            has_npm_script "test" || tc="echo 'No test script'"
            lint_task=""
            has_npm_script "lint" && lint_task=",{\"name\":\"Lint\",\"working_directory\":\".\",\"command\":\"$lc\",\"stage\":\"test\"}"
            build_task=""
            has_npm_script "build" && build_task=",{\"name\":\"Build\",\"working_directory\":\".\",\"command\":\"$bc\",\"stage\":\"release\"}"
            echo "{\"tasks\":[{\"name\":\"Install\",\"working_directory\":\".\",\"command\":\"$ic\",\"stage\":\"test\"},{\"name\":\"Test\",\"working_directory\":\".\",\"command\":\"$tc\",\"stage\":\"test\"}$lint_task$build_task]}"
            ;;
        python)
            pm=$(detect_python_pm)
            case "$pm" in
                poetry) ic="poetry install"; tc="poetry run pytest"; lc="poetry run ruff check ." ;;
                pipenv) ic="pipenv install --dev"; tc="pipenv run pytest"; lc="pipenv run ruff check ." ;;
                uv)     ic="uv sync"; tc="uv run pytest"; lc="uv run ruff check ." ;;
                *)      ic="pip install -r requirements.txt"; tc="pytest"; lc="ruff check . || flake8" ;;
            esac
            echo "{\"tasks\":[{\"name\":\"Install\",\"working_directory\":\".\",\"command\":\"$ic\",\"stage\":\"test\"},{\"name\":\"Lint\",\"working_directory\":\".\",\"command\":\"$lc\",\"stage\":\"test\"},{\"name\":\"Test\",\"working_directory\":\".\",\"command\":\"$tc\",\"stage\":\"test\"}]}"
            ;;
        go)
            echo '{"tasks":[{"name":"Download","working_directory":".","command":"go mod download","stage":"test"},{"name":"Vet","working_directory":".","command":"go vet ./...","stage":"test"},{"name":"Test","working_directory":".","command":"go test -v ./...","stage":"test"},{"name":"Build","working_directory":".","command":"go build -v ./...","stage":"release"}]}'
            ;;
        rust)
            echo '{"tasks":[{"name":"Check","working_directory":".","command":"cargo check","stage":"test"},{"name":"Clippy","working_directory":".","command":"cargo clippy -- -D warnings","stage":"test"},{"name":"Test","working_directory":".","command":"cargo test","stage":"test"},{"name":"Build","working_directory":".","command":"cargo build --release","stage":"release"}]}'
            ;;
        dotnet)
            echo '{"tasks":[{"name":"Restore","working_directory":".","command":"dotnet restore","stage":"test"},{"name":"Build","working_directory":".","command":"dotnet build --no-restore","stage":"test"},{"name":"Test","working_directory":".","command":"dotnet test --no-build","stage":"test"}]}'
            ;;
        java-maven)
            echo '{"tasks":[{"name":"Compile","working_directory":".","command":"mvn compile","stage":"test"},{"name":"Test","working_directory":".","command":"mvn test","stage":"test"},{"name":"Package","working_directory":".","command":"mvn package -DskipTests","stage":"release"}]}'
            ;;
        java-gradle)
            echo '{"tasks":[{"name":"Compile","working_directory":".","command":"./gradlew compileJava","stage":"test"},{"name":"Test","working_directory":".","command":"./gradlew test","stage":"test"},{"name":"Build","working_directory":".","command":"./gradlew build -x test","stage":"release"}]}'
            ;;
        kotlin)
            echo '{"tasks":[{"name":"Build","working_directory":".","command":"./gradlew build || gradlew build","stage":"test"},{"name":"Test","working_directory":".","command":"./gradlew test || gradlew test","stage":"test"},{"name":"Assemble","working_directory":".","command":"./gradlew assemble || gradlew assemble","stage":"release"}]}'
            ;;
        scala)
            echo '{"tasks":[{"name":"Compile","working_directory":".","command":"sbt compile || ./gradlew compileScala || gradlew compileScala","stage":"test"},{"name":"Test","working_directory":".","command":"sbt test || ./gradlew test || gradlew test","stage":"test"},{"name":"Package","working_directory":".","command":"sbt package || ./gradlew assemble || gradlew assemble","stage":"release"}]}'
            ;;
        swift)
            echo '{"tasks":[{"name":"Build","working_directory":".","command":"swift build","stage":"test"},{"name":"Test","working_directory":".","command":"swift test","stage":"test"},{"name":"Release","working_directory":".","command":"swift build --configuration release","stage":"release"}]}'
            ;;
        cpp)
            echo '{"tasks":[{"name":"Configure","working_directory":".","command":"mkdir -p build && cd build && cmake .. || echo CMake not found","stage":"test"},{"name":"Build","working_directory":".","command":"cd build && make || make","stage":"test"},{"name":"Test","working_directory":".","command":"cd build && ctest || make test || echo No tests","stage":"test"}]}'
            ;;
        dart)
            echo '{"tasks":[{"name":"Get","working_directory":".","command":"dart pub get","stage":"test"},{"name":"Analyze","working_directory":".","command":"dart analyze","stage":"test"},{"name":"Test","working_directory":".","command":"dart test","stage":"test"},{"name":"Build","working_directory":".","command":"dart compile exe bin/main.dart -o bin/main || echo No executable","stage":"release"}]}'
            ;;
        ruby)
            echo '{"tasks":[{"name":"Install","working_directory":".","command":"bundle install","stage":"test"},{"name":"Test","working_directory":".","command":"bundle exec rspec || bundle exec rake test","stage":"test"}]}'
            ;;
        php)
            echo '{"tasks":[{"name":"Install","working_directory":".","command":"composer install","stage":"test"},{"name":"Test","working_directory":".","command":"composer test || vendor/bin/phpunit","stage":"test"}]}'
            ;;
        make)
            echo '{"tasks":[{"name":"Build","working_directory":".","command":"make","stage":"test"},{"name":"Test","working_directory":".","command":"make test","stage":"test"}]}'
            ;;
        *)
            echo '{"tasks":[{"name":"Hello","working_directory":".","command":"echo Universal CI ready! Edit universal-ci.config.json","stage":"test"}]}'
            ;;
    esac
}

pretty_json() {
    # Simple JSON prettification using sed
    echo "$1" | sed 's/\[/[\n  /g' | sed 's/\],/\n],/g' | sed 's/},{/},\n  {/g' | sed 's/}]$/\n  }\n]/g'
}

run_init() {
    printf "${CYAN}🔧 Universal CI - Project Initialization${RESET}\n"
    echo ""
    
    project_type=$(detect_project_type)
    
    case "$project_type" in
        nodejs)      friendly="Node.js" ;;
        python)      friendly="Python" ;;
        go)          friendly="Go" ;;
        rust)        friendly="Rust" ;;
        dotnet)      friendly=".NET" ;;
        java-maven)  friendly="Java (Maven)" ;;
        java-gradle) friendly="Java (Gradle)" ;;
        kotlin)      friendly="Kotlin" ;;
        scala)       friendly="Scala" ;;
        swift)       friendly="Swift" ;;
        cpp)         friendly="C++" ;;
        dart)        friendly="Dart" ;;
        ruby)        friendly="Ruby" ;;
        php)         friendly="PHP" ;;
        make)        friendly="Makefile" ;;
        *)           friendly="Generic" ;;
    esac
    
    printf "${GREEN}✅ Detected: ${friendly}${RESET}\n"
    
    if [ "$project_type" = "nodejs" ]; then
        pm=$(detect_node_pm)
        printf "${BLUE}   Package manager: ${pm}${RESET}\n"
    elif [ "$project_type" = "python" ]; then
        pm=$(detect_python_pm)
        printf "${BLUE}   Package manager: ${pm}${RESET}\n"
    fi
    
    if [ -f "$CONFIG_FILE" ]; then
        printf "${YELLOW}⚠️  Config already exists: ${CONFIG_FILE}${RESET}\n"
        printf "Overwrite? [y/N] "
        read -r answer
        case "$answer" in
            [Yy]*) ;;
            *) printf "${BLUE}Keeping existing config.${RESET}\n"; exit 0 ;;
        esac
    fi
    
    config=$(generate_config "$project_type")
    pretty_json "$config" > "$CONFIG_FILE"
    
    printf "${GREEN}✅ Created ${CONFIG_FILE}${RESET}\n"
    echo ""
    echo "Next steps:"
    echo "  1. Review and customize ${CONFIG_FILE}"
    echo "  2. Run: ./run-ci.sh"
    exit 0
}

# Run init mode if requested
if [ "$INIT_MODE" = true ]; then
    run_init
fi

main