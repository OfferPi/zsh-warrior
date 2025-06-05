# default shortcut as Ctrl-o
(( ! ${+ZSH_WARRIOR_HOTKEY} )) && typeset -g ZSH_WARRIOR_HOTKEY='^o'
# default python3 path
(( ! ${+ZSH_WARRIOR_PYTHON3} )) && typeset -g ZSH_WARRIOR_PYTHON3='python3'
# default logfile path unset (logs to stderr)
(( ! ${+ZSH_WARRIOR_LOGFILE} )) && typeset -g ZSH_WARRIOR_LOGFILE=''
# default Ollama endpoint URL
(( ! ${+ZSH_WARRIOR_ENDPOINT} )) && typeset -g ZSH_WARRIOR_ENDPOINT='http://localhost:11434'
# default Ollama model
(( ! ${+ZSH_WARRIOR_MODEL} )) && typeset -g ZSH_WARRIOR_MODEL='qwen2.5-coder:3b'
# default temperature (as a string) for generation
(( ! ${+ZSH_WARRIOR_TEMP} )) && typeset -g ZSH_WARRIOR_TEMP='0.5'
# default ollama time to keep the server alive
(( ! ${+ZSH_WARRIOR_KEEP_ALIVE} )) && typeset -g ZSH_WARRIOR_KEEP_ALIVE='1h'


#
# Helper: create .venv and install ollama (only once), without activating.
#
ensure_venv_exists() {
  local PLUGIN_DIR="$1"
  local VENV_DIR="$PLUGIN_DIR/.venv"

  # If .venv is already there, do nothing.
  if [ -d "$VENV_DIR" ]; then
    return 0
  fi

  print -u1 "Setting up virtual environment (one-time)..."
  "$ZSH_WARRIOR_PYTHON3" -m venv "$VENV_DIR"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create virtual environment at $VENV_DIR."
    return 1
  fi

  # Use the venv's pip directly, avoid sourcing here.
  "$VENV_DIR/bin/pip" install --upgrade pip > /dev/null 2>&1
  "$VENV_DIR/bin/pip" install ollama > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install ollama in virtual environment."
    return 1
  fi

  return 0
}


#
# Main widget: activate venv, run llm_wrapper.py, then deactivate.
#
zsh_warrior() {
  ZSH_WARRIOR_USER_QUERY=$BUFFER

  zle end-of-line
  zle reset-prompt

  print
  print -u1 "🦙Generating Command..."

  # Export environment variables for the Python script
  export ZSH_WARRIOR_LOGFILE
  export ZSH_WARRIOR_ENDPOINT
  export ZSH_WARRIOR_MODEL
  export ZSH_WARRIOR_TEMP
  export ZSH_WARRIOR_KEEP_ALIVE

  # Locate this plugin’s directory
  PLUGIN_DIR=${${(%):-%x}:A:h}
  VENV_DIR="$PLUGIN_DIR/.venv"

  # Activate the existing venv
  if [ ! -d "$VENV_DIR" ]; then
    echo "Error: Virtual environment missing at $VENV_DIR."
    return 1
  fi

  source "$VENV_DIR/bin/activate"

  # Run the Python wrapper inside the activated venv
  ZSH_WARRIOR_COMMAND=$(
    "$VENV_DIR/bin/python" \
      "$PLUGIN_DIR/llm_wrapper.py" "$ZSH_WARRIOR_USER_QUERY"
  )

  # Deactivate the venv
  deactivate >/dev/null 2>&1

  # If something went wrong or empty response
  if [ $? -ne 0 ] || [ -z "$ZSH_WARRIOR_COMMAND" ]; then
    echo "Error: Failed to parse commands"
    echo "Raw response:"
    echo "$ZSH_WARRIOR_COMMAND"
    return 0
  fi

  # Remove the “Generating Command...” line
  tput cuu 1

  # Insert the generated command into the buffer
  BUFFER="$ZSH_WARRIOR_COMMAND"
  CURSOR=${#BUFFER}

  # Don’t accept the line automatically
  zle -R
  zle reset-prompt

  return 0
}


# When this file is sourced, immediately ensure the venv exists.
PLUGIN_DIR=${${(%):-%x}:A:h}
ensure_venv_exists "$PLUGIN_DIR"


autoload -U zsh_warrior
zle -N zsh_warrior
bindkey "$ZSH_WARRIOR_HOTKEY" zsh_warrior
