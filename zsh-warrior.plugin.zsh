# Loading environment variables
# Default shortcut as Ctrl-o
(( ! ${+ZSH_WARRIOR_HOTKEY} )) && typeset -g ZSH_WARRIOR_HOTKEY='^o'
# Default python3 path
(( ! ${+ZSH_WARRIOR_PYTHON3} )) && typeset -g ZSH_WARRIOR_PYTHON3='python3'
# Default logfile path unset (logs to stderr)
(( ! ${+ZSH_WARRIOR_LOGFILE} )) && typeset -g ZSH_WARRIOR_LOGFILE=''
# Default Ollama endpoint URL
(( ! ${+ZSH_WARRIOR_ENDPOINT} )) && typeset -g ZSH_WARRIOR_ENDPOINT='http://localhost:11434'
# Default Ollama model
(( ! ${+ZSH_WARRIOR_MODEL} )) && typeset -g ZSH_WARRIOR_MODEL='qwen2.5-coder:3b'
# Default temperature (as a string) for generation
(( ! ${+ZSH_WARRIOR_TEMP} )) && typeset -g ZSH_WARRIOR_TEMP='0.5'
# Default Ollama time to keep the server alive
(( ! ${+ZSH_WARRIOR_KEEP_ALIVE} )) && typeset -g ZSH_WARRIOR_KEEP_ALIVE='1h'

# Source helpers
source "$(dirname "${(%):-%x}")/zsh-warrior_helpers.zsh"

#
# Main widget: activate venv, run llm_wrapper.py, then deactivate.
#
zsh_warrior() {
  ZSH_WARRIOR_USER_QUERY=$BUFFER

  zle end-of-line
  zle reset-prompt

  print
  print -u1 "🦙Generating Command..."
  log "Received user query: $ZSH_WARRIOR_USER_QUERY"

  # Check if Ollama is up and running
  if ! check_ollama_reachable; then
    # If not reachable, abort and return to prompt
    log "Aborting: Ollama not reachable."
    return 1
  fi

  # Export environment variables for the Python script
  export ZSH_WARRIOR_LOGFILE
  export ZSH_WARRIOR_ENDPOINT
  export ZSH_WARRIOR_MODEL
  export ZSH_WARRIOR_TEMP
  export ZSH_WARRIOR_KEEP_ALIVE

  log "Exported environment variables."

  # Locate this plugin’s directory
  PLUGIN_DIR=${${(%):-%x}:A:h}
  VENV_DIR="$PLUGIN_DIR/.venv"
  log "Plugin directory resolved to $PLUGIN_DIR"

  # Activate the existing venv
  if [ ! -d "$VENV_DIR" ]; then
    echo "Error: Virtual environment missing at $VENV_DIR."
    log "ERROR: Virtual environment missing. Attempting to create."
    ensure_venv_exists "$PLUGIN_DIR"
    if [ $? -ne 0 ]; then
      log "ERROR: Could not create virtual environment. Aborting."
      return 1
    fi
  fi

  log "Sourcing virtual environment at $VENV_DIR"
  source "$VENV_DIR/bin/activate"

  # Run the Python wrapper inside the activated venv
  ZSH_WARRIOR_COMMAND=$(
    "$VENV_DIR/bin/python" \
      "$PLUGIN_DIR/llm_wrapper.py" "$ZSH_WARRIOR_USER_QUERY"
  )
  log "Python wrapper returned: $ZSH_WARRIOR_COMMAND"

  # Deactivate the venv
  deactivate >/dev/null 2>&1
  log "Deactivated virtual environment."

  # If something went wrong or empty response
  if [ $? -ne 0 ] || [ -z "$ZSH_WARRIOR_COMMAND" ]; then
    echo "Error: Failed to parse commands"
    echo "Raw response:"
    echo "$ZSH_WARRIOR_COMMAND"
    log "ERROR: Failed to parse commands or empty response."
    return 0
  fi

  # Remove the “Generating Command...” line
  tput cuu 1

  # Insert the generated command into the buffer
  BUFFER="$ZSH_WARRIOR_COMMAND"
  CURSOR=${#BUFFER}
  log "Inserted generated command into buffer."

  # Don’t accept the line automatically
  zle -R
  zle reset-prompt

  return 0
}

# Check for python3
if ! command -v "$ZSH_WARRIOR_PYTHON3" >/dev/null 2>&1; then
  echo "Error: python3 not found. Please install Python 3 and ensure 'python3' is in your PATH."
  log "ERROR: python3 not found in PATH."
  return 1
fi
log "python3 found at $(command -v $ZSH_WARRIOR_PYTHON3)"

# Check if Ollama is running
if ! check_ollama_reachable; then
  log "ERROR: Ollama not reachable at startup."
  return 1
fi

# Check if the venv exists.
PLUGIN_DIR=${${(%):-%x}:A:h}
ensure_venv_exists "$PLUGIN_DIR"

autoload -U zsh_warrior
zle -N zsh_warrior
bindkey "$ZSH_WARRIOR_HOTKEY" zsh_warrior
