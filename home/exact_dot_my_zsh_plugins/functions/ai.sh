function ai {
    if [ $# -eq 0 ]; then
        echo "Usage: ai <your request>"
        return 1
    fi

    local request="$*"
    local schema='{
  "type": "object",
  "properties": {
    "command": {
      "type": "string",
      "description": "The executable bash/zsh command or script"
    }
  },
  "required": ["command"]
}'

    local command_output=$(claude \
        --print \
        --output-format json \
        --json-schema "$schema" \
        "Generate a single executable bash/zsh command or script for: ${request}

REQUIREMENTS:
- Output only the command/script in the 'command' field
- The user's shell is: ${SHELL}
- Use standard Unix tools plus fzf and ripgrep (rg) which are available
- Chain multiple commands with && or ; if needed
- Follow best practices and ensure safety" | jq -r '.structured_output.command')

    print -z "$command_output"
}
