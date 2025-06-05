# zsh-warrior

A plugin for oh-my-zsh that uses a large language model to translate natural-language into Zsh commands.

## Features

- **Natural-language to commands:** Describe what you want in natural-language, and *zsh-warrior* instantly converts it into an executable Zsh command.
- **On-device LLM (Ollama):** Uses models run locally by [Ollama](https://ollama.com/) . All inference happens on-device (offline and private), so your queries are secure and fast.

## Requirements

- `Python 3` for communication with ollama
- `curl` To check the status of Ollama
- `Ollama` For running the Models

## Installation

1.  **Clone the repository:** Put *zsh-warrior* into your Oh My Zsh custom plugins folder:
    
    ```sh
    git clone https://github.com/OfferPi/zsh-warrior.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-warrior
    ```
    
2.  **Enable the plugin:** Edit your `~/.zshrc` and add `zsh-warrior` to the `plugins=(…)` list:
    
    ```zsh
    plugins=(
      git
      zsh-warrior
    )
    ```
    
3.  **Restart or reload Zsh:** Close and reopen your terminal, or run `source ~/.zshrc`, to activate the plugin.
    

## Configuration Variables

| Variable | Default | Description |
| --- | --- | --- |
| `ZSH_WARRIOR_HOTKEY` | `^o` (Ctrl-o) | Key binding to trigger the plugin |
| `ZSH_WARRIOR_PYTHON3` | `python3` | Path to the Python 3 executable |
| `ZSH_WARRIOR_LOGFILE` | (empty) | File path for debug logs. If unset, logs go to stderr. |
| `ZSH_WARRIOR_ENDPOINT` | `http://localhost:11434` | URL of the Ollama API endpoint |
| `ZSH_WARRIOR_MODEL` | `qwen2.5-coder:3b` | Ollama model name used for inference |
| `ZSH_WARRIOR_TEMP` | `0.5` | Temperature setting for the LLM (controls randomness) |
| `ZSH_WARRIOR_KEEP_ALIVE` | `1h` | How long Ollama service should stay alive |

## Usage

- **Type a description:** In your Zsh prompt, just start typing what you want the shell to do, in plain English. For example: `resize all images in this folder to 800x600`.
- **Press the hotkey:** Hit the shortcut (default **Ctrl-o**) to trigger *zsh-warrior*. The plugin will send your query to the local Ollama LLM.
- **Get the command:** Ollama returns a generated command (e.g. an `mogrify` or `find` command) and *zsh-warrior* inserts it into your prompt.

## Acknowledgements
Inspired by the work of [keyvez](https://github.com/keyvez/kollzsh).
