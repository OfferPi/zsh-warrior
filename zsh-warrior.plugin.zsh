# default shortcut as Ctrl-o
(( ! ${+ZSH_WARRIOR_HOTKEY} )) && typeset -g ZSH_WARRIOR_HOTKEY='^o'
# default logfile path unset (logs to stderr)
(( ! ${+ZSH_WARRIOR_PYTHON3} )) && typeset -g ZSH_WARRIOR_PYTHON3='python3'
# default Ollama endpoint URL
(( ! ${+ZSH_WARRIOR_LOGFILE} )) && typeset -g ZSH_WARRIOR_LOGFILE=''
# default python3 path
(( ! ${+ZSH_WARRIOR_ENDPOINT} )) && typeset -g ZSH_WARRIOR_ENDPOINT='http://localhost:11434'
# default Ollama model
(( ! ${+ZSH_WARRIOR_MODEL} )) && typeset -g ZSH_WARRIOR_MODEL='qwen2.5-coder:3b'
# default temperature (as a string) for generation
(( ! ${+ZSH_WARRIOR_TEMP} )) && typeset -g ZSH_WARRIOR_TEMP='0.5'
# default ollama time to keep the server alive
(( ! ${+ZSH_WARRIOR_KEEP_ALIVE} )) && typeset -g ZSH_WARRIOR_KEEP_ALIVE='1h'

zsh_warrior() {
  setopt extendedglob
  validate_required
  if [ $? -eq 1 ]; then
    return 1
  fi

  ZSH_WARRIOR_USER_QUERY=$BUFFER

  zle end-of-line
  zle reset-prompt

  print
  print -u1 "🦙Generating Command..."

  # Export necessary environment variables to be used by the python script
  export ZSH_WARRIOR_LOGFILE
  export ZSH_WARRIOR_ENDPOINT
  export ZSH_WARRIOR_MODEL
  export ZSH_WARRIOR_TEMP
  export ZSH_WARRIOR_KEEP_ALIVE

  # Get absolute path to the script directory
  PLUGIN_DIR=${${(%):-%x}:A:h}
  ZSH_WARRIOR_COMMAND=$( "$ZSH_WARRIOR_PYTHON3" "$PLUGIN_DIR/llm_wrapper.py" "$ZSH_WARRIOR_USER_QUERY")
  
  # Check if the command was successful and that the commands is an array
  if [ $? -ne 0 ] || [ -z "$ZSH_WARRIOR_COMMAND" ]; then
    echo "Error: Failed to parse commands"
    echo "Raw response:"
    echo "$KOLLZSH_COMMAND"
    return 0
  fi
  
  tput cuu 1 # cleanup waiting message

  BUFFER="$ZSH_WARRIOR_COMMAND"
  CURSOR=${#BUFFER}  # Move cursor to end of buffer
    
  # Ensure we're not accepting the line
  zle -R
  zle reset-prompt

  return 0
}

autoload -U zsh_warrior
zle -N zsh_warrior
bindkey "$ZSH_WARRIOR_HOTKEY" zsh_warrior
