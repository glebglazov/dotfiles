function claude-docker {
    local image_name="claude-code"
    local state_volume="claude-state"
    local global_config="$HOME/.config/claude-docker/config.json"
    local local_config="./claude-docker.json"

    # Build image if it doesn't exist
    if ! docker image inspect "$image_name" &>/dev/null; then
        echo "Building claude-code Docker image..."
        docker build -t "$image_name" - <<'DOCKERFILE'
FROM node:20
RUN npm install -g @anthropic-ai/claude-code
ENTRYPOINT ["claude", "--dangerously-skip-permissions"]
DOCKERFILE
        if [ $? -ne 0 ]; then
            echo "Failed to build Docker image"
            return 1
        fi
    fi

    # Merge global and local configs (arrays concatenated, local adds to global)
    local empty='{"mounts":[],"env":[]}'
    local global_cfg="${empty}"
    local local_cfg="${empty}"
    [ -f "$global_config" ] && global_cfg=$(cat "$global_config")
    [ -f "$local_config" ] && local_cfg=$(cat "$local_config")

    local merged
    merged=$(jq -n \
        --argjson g "$global_cfg" \
        --argjson l "$local_cfg" \
        '{mounts: (($g.mounts // []) + ($l.mounts // []) | unique), env: (($g.env // []) + ($l.env // []) | unique)}')

    # Volume mounts: workspace + persistent state + host credentials
    local docker_args=()
    docker_args+=(-v "$(pwd):/workspace")
    docker_args+=(-v "${state_volume}:/root/.claude")
    [ -f "$HOME/.claude.json" ] && docker_args+=(-v "$HOME/.claude.json:/root/.claude.json:ro")

    # Shadow all .envrc files with /dev/null so the agent can't read them
    while IFS= read -r envrc; do
        local rel_path="${envrc#./}"
        docker_args+=(--mount "type=bind,source=/dev/null,target=/workspace/${rel_path},readonly")
    done < <(find . -name ".envrc" -not -path "./.git/*" 2>/dev/null)

    # Additional mounts from config (expand env vars in paths)
    while IFS= read -r mount; do
        [ -n "$mount" ] && docker_args+=(-v "$(eval echo "$mount")")
    done < <(echo "$merged" | jq -r '.mounts[]')

    # Environment variable allowlist from config
    while IFS= read -r var; do
        [ -n "$var" ] && [ -n "${(P)var}" ] && docker_args+=(-e "$var=${(P)var}")
    done < <(echo "$merged" | jq -r '.env[]')

    docker run --rm -it \
        -e CLAUDE_CODE_OAUTH_TOKEN="$CONTAINER_CLAUDE_CODE_TOKEN" \
        -e IS_SANDBOX=1 \
        -e TERM="$TERM" \
        "${docker_args[@]}" \
        -w /workspace \
        "$image_name" "$@"
}
