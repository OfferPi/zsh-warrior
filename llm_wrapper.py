#!/usr/bin/env python3
import os      # For accessing environment variables and file paths
import sys     # For accessing command-line arguments and exiting the script
import re      # For regular expressions used in extracting commands
import logging # For logging info, warnings, and errors to a file or stderr
from datetime import datetime  # Not directly used in the current code but often for timestamps

from ollama import Client  # Ollama client for interacting with the LLM API


def configure_logging():
    """
    Configure the logging settings, writing to a logfile if specified.
    """
    # Try to read the log file path from an environment variable.
    log_file = os.getenv('ZSH_WARRIOR_LOGFILE')
    if log_file:
        # If a logfile path exists, log INFO and higher to that file.
        logging.basicConfig(
            filename=log_file,
            level=logging.INFO,
            format="%(asctime)s - %(levelname)s - %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S"
        )
        logging.info(f"Logging initialized. Writing to logfile: {log_file}")
    else:
        # Otherwise, log ERROR and higher to stderr with a simple format.
        logging.basicConfig(
            level=logging.ERROR,
            format="%(asctime)s - %(levelname)s - %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S"
        )
        logging.info("Logging initialized. No logfile specified, outputting to stderr.")


def extract_command(llm_response: str) -> str:
    """
    Given a string containing an LLM‐generated shell command (possibly in 
    ```bash```, ```zsh```, or ```sh``` fences—or inline backticks), return 
    just the command itself on one line.
    """
    # 1. Look for a fenced code block labeled bash, zsh, or sh.
    fenced = re.search(r"```(?:bash|zsh|sh)?\s*([\s\S]*?)```", llm_response)
    if fenced:
        # If found, group(1) contains the text inside that fence.
        cmd_text = fenced.group(1)
    else:
        # 2. If no fenced block, check for inline backticks (e.g., `ls -la`).
        inline = re.search(r"`([^`]*)`", llm_response)
        if inline:
            cmd_text = inline.group(1)
        else:
            # 3. If no markdown syntax at all, assume the whole response is the command.
            cmd_text = llm_response

    # 4. Normalize whitespace: strip leading/trailing spaces
    #    and collapse multiple spaces/newlines into a single space.
    one_liner = " ".join(cmd_text.strip().split())

    # Return the cleaned-up, single-line command.
    return one_liner


def get_config() -> dict:
    """
    Collects config values from environment variables.
    Always returns a complete config dictionary.
    """
    # Default settings in case env vars aren’t set.
    default_config = {
        "host": "http://localhost:11434",    # Ollama default endpoint
        "model": "qwen2.5-coder:3b",         # Default model to use
        "temperature": 0.5,                  # Default randomness setting
        "logging": False,                    # Default logging state
    }

    config = {}

    # Read host from ZSH_WARRIOR_ENDPOINT, fallback to default_config["host"]
    config["host"] = os.getenv('ZSH_WARRIOR_ENDPOINT', default_config["host"])
    # Read model from ZSH_WARRIOR_MODEL, fallback to default_config["model"]
    config["model"] = os.getenv('ZSH_WARRIOR_MODEL', default_config["model"])

    # Read temperature from ZSH_WARRIOR_TEMP (no default).
    temp_env = os.getenv('ZSH_WARRIOR_TEMP')
    if temp_env is not None:
        try:
            # Try converting to float
            config["temperature"] = float(temp_env)
        except ValueError:
            # Log a warning and use the default if conversion fails
            logging.warning(
                f"Invalid ZSH_WARRIOR_TEMP='{temp_env}'. "
                f"Falling back to default ({default_config['temperature']})."
            )
            config["temperature"] = default_config["temperature"]
    else:
        # No env var set; use the default directly
        config["temperature"] = default_config["temperature"]

    # Log the final config
    logging.info(
        f"Config loaded: host={config['host']}, "
        f"model={config['model']}, temperature={config['temperature']}"
    )
    return config


def ask_ollama(user_query: str, config: dict) -> str:
    """
    Send the user query to Ollama and return a single Zsh command.
    """
    # Create a client instance pointing at the configured host.
    client = Client(host=config["host"])

    # Prepare the “system” message that instructs the LLM.
    system_message = (
        "You are a Zsh shell expert."
        "Output only the exact Zsh command that solves the user’s request."
        "No explanation, no formatting, no extra text."
        "Your response must be a single line of valid Zsh code ready to run in the terminal."
    )

    # Construct the chat payload: system + user messages.
    messages = [
        {"role": "system", "content": system_message},
        {"role": "user",   "content": user_query},
    ]

    try:
        # Log the query being sent.
        logging.info(f"Sending query to Ollama: {user_query}")
        # Call the Ollama API without streaming.
        response = client.chat(
            model=config["model"],
            messages=messages,
            stream=False,
            options={"temperature": config["temperature"]}
        )
        # Extract the “content” field from the response message.
        message = response.get('message', {}).get('content', '')
        # Run our helper to strip markdown and whitespace.
        command = extract_command(message)
        if command:
            logging.info(f"Received command: {command}")
            return command
        else:
            # If nothing valid was found, log an error and return a message.
            logging.error("No valid Zsh command found in Ollama response.")
            return "Error: No valid Zsh command found."

    except Exception as e:
        # If anything goes wrong (network, API error, etc.), catch it.
        logging.exception("Error while contacting Ollama API.")
        return f"Error: something went wrong! {e}"


if __name__ == "__main__":
    # Set up logging as early as possible.
    configure_logging()

    # Expect exactly one argument: the user’s query.
    if len(sys.argv) < 2:
        logging.error("No user query provided. Usage: script.py '<query>'")
        print("Error: No user query provided. Please provide a query as an argument.")
        sys.exit(1)  # Exit with a non‐zero code to indicate failure.

    # Grab the query from the command line arguments.
    user_query = sys.argv[1]
    # Load configuration from environment or defaults.
    config = get_config()

    try:
        # Ask Ollama for the Zsh command and print it.
        command = ask_ollama(user_query, config)
        print(command)
    except Exception as e:
        # Catch any unexpected exceptions in the main flow.
        logging.exception("Unexpected error in main execution.")
        print(f"Error: {e}")
