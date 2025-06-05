#!/usr/bin/env bash

# Define 20 zsh‐command instructions as questions
questions=(
  "remove the first line of all .txt files in current dir"
  "list all files modified in the last 24 hours"
  "find all .py files containing the string 'TODO'"
  "replace spaces with underscores in all filenames in current dir"
  "count the number of lines in each .log file"
  "archive all .csv files older than 7 days into a tar.gz"
  "show the disk usage of each subdirectory in human‐readable format"
  "kill all processes named 'node'"
  "download all images from a webpage given its URL"
  "search for 'error' in all .conf files and display filenames"
  "monitor CPU usage every 5 seconds and log to cpu.log"
  "create a backup of /etc directory with a timestamped filename"
  "sync two directories keeping permissions intact"
  "display the top 10 largest files in current directory"
  "compress all .jpg files into a zip archive"
  "replace 'foo' with 'bar' in all .md files recursively"
  "show all listening TCP ports"
  "find and delete all empty directories under /tmp"
  "copy all .mp3 files to a directory named MusicBackup"
  "count how many times 'ssh' appears in syslog files"
)

# Loop over each question
for question in "${questions[@]}"; do
  # Repeat each question 3 times
  for run in {1..3}; do
    # Invoke the Python wrapper and capture its output
    answer="$(python3 llm_wrapper.py "$question")"

    echo "Question: $question"
    echo "Run #$run Answer:"
    echo "$answer"
    echo "----------------------------------------"
  done
done

echo "All questions executed. Results are in $output_file."

