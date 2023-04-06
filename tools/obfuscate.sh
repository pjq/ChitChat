#!/bin/bash

# List of sensitive words, separated by '|'
sensitive_words="sensitive_word1|sensitive_word2|sensitive_word3"

# Generate obfuscated words
obfuscated_words="$(echo "$sensitive_words" | sed -E 's/[^|]+/obf_\w{5}/g')"

# List of file extensions to exclude from obfuscation
exclude_files="(\.arb|\.png|\.jpg|\.jpeg|\.gif|\.ico|\.svg|\.woff|\.woff2|\.ttf|\.eot|\.otf|\.mp3|\.mp4|\.avi|\.mkv|\.pdf|\.zip|\.tar|\.gz|\.bz2|\.xz|\.sqlite|\.bin|\.exe)$"

# Output file
output_file="obfuscated_structure.txt"

# Parse command-line arguments
project_dir=

while [[ $# -gt 0 ]]; do
  case $1 in
    --dir) project_dir="$2"; shift ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

if [[ -z $project_dir ]]; then
  echo "Please specify the project directory with --dir"
  exit 1
fi

# Remove output file if it exists
if [[ -f $output_file ]]; then
  rm -f "$output_file"
fi

# Function to obfuscate file content
obfuscate_file() {
  local file="$1"
  local src="$sensitive_words"
  local dst="$obfuscated_words"
  local cmd="cat '$file'"

  while IFS= read -r -d '|' src_word && IFS= read -r -d '|' dst_word; do
    cmd+=" | sed 's/$src_word/$dst_word/g'"
  done < <(echo "$src" | tr '|' '\n') < <(echo "$dst" | tr '|' '\n')

  eval "$cmd"
}

# Output file structures
echo "File structures" >> "$output_file"
echo  '```' >> "$output_file"
find "$project_dir" -type d | sed 's|^|/|g' >> "$output_file"
echo  '```' >> "$output_file"

# Output file contents
echo "File contents:" >> "$output_file"

# Process each file in the project directory
while IFS= read -r -d '' file; do
  # Check if file is not in the exclude list
  if [[ ! "$file" =~ $exclude_files ]]; then
    echo  "" >> "$output_file"
    echo  "$file" >> "$output_file"
    echo  '```' >> "$output_file"
    obfuscate_file "$file" >> "$output_file"
    echo  '```' >> "$output_file"
  fi
done < <(find "$project_dir" -type f -print0)

echo "Obfuscated project structure created in $output_file"
