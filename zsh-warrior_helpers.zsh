#
# Helper: Write logs to $ZSH_WARRIOR_LOGFILE if set.
#
log() {
  if [[ -n "$ZSH_WARRIOR_LOGFILE" ]]; then
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    # Ensure logfile directory exists
    mkdir -p "$(dirname "$ZSH_WARRIOR_LOGFILE")"
    echo "[$ts] $*" >> "$ZSH_WARRIOR_LOGFILE"
  fi
}

#
# Helper: create .venv and install ollama (only once), without activating.
#
ensure_venv_exists() {
  local PLUGIN_DIR="$1"
  local VENV_DIR="$PLUGIN_DIR/.venv"

  log "Checking if venv exists at $VENV_DIR"
  # If .venv is already there, do nothing.
  if [ -d "$VENV_DIR" ]; then
    log "Virtual environment already exists."
    return 0
  fi

  print -u1 "Setting up virtual environment (one-time)..."
  log "Creating virtual environment at $VENV_DIR"
  "$ZSH_WARRIOR_PYTHON3" -m venv "$VENV_DIR"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create virtual environment at $VENV_DIR."
    log "ERROR: Failed to create virtual environment."
    return 1
  fi

  print -u1 "Installing ollama module in virtual environment🦙 ..."
  log "Installing ollama via pip in $VENV_DIR"
  # Use the venv's pip directly, avoid sourcing here.
  "$VENV_DIR/bin/pip" install --upgrade pip > /dev/null 2>&1
  "$VENV_DIR/bin/pip" install ollama > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install ollama in virtual environment."
    log "ERROR: Failed to install ollama in virtual environment."
    return 1
  fi

  log "Successfully set up venv and installed ollama."
  return 0
}

#
# Helper: Check if ollama endpoint is reachable
#
check_ollama_reachable() {
  log "Checking Ollama endpoint reachability at $ZSH_WARRIOR_ENDPOINT"
  # Check basic reachability (timeout after 5 seconds)
  if ! curl --silent --head --fail --max-time 5 "$ZSH_WARRIOR_ENDPOINT" >/dev/null 2>&1; then
    echo "Error: Cannot reach $ZSH_WARRIOR_ENDPOINT." 
    echo "Make sure Ollama is installed and running. For more info go to: https://ollama.readthedocs.io/en/quickstart/"
    log "ERROR: Ollama endpoint $ZSH_WARRIOR_ENDPOINT not reachable."
    return 1
  fi

  # Try to fetch the version JSON from Ollama
  local version_json
  version_json=$(curl --silent --fail --max-time 5 "$ZSH_WARRIOR_ENDPOINT/api/version")
  if [[ $? -ne 0 ]]; then
    echo "Error: Unable to fetch /api/version. $ZSH_WARRIOR_ENDPOINT might not be Ollama."
    echo "Make sure Ollama is installed and running. For more info go to: https://ollama.readthedocs.io/en/quickstart/"
    log "ERROR: Unable to fetch version from Ollama endpoint."
    return 1
  fi

  log "Ollama endpoint reachable. Version info fetched."
  return 0
}
