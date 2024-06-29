#!/bin/bash

LANGUAGE=$1
CODE=$2
INPUT_FILE=$3

execute_code() {
  cmd=$1
  code=$2
  input_file=$3


  mkdir -p /home/executor/sandbox
  cp $(which $cmd) /home/executor/sandbox/ 
  chmod +x /home/executor/sandbox/$(basename $cmd)
  echo "$input_file" > /home/executor/sandbox/input

  if [[ $cmd == "python3" ]]; then
    if [[ -z "$input_file" ]]; then
      echo "$code" > /home/executor/sandbox/code
    else
      echo -e "with open('/home/executor/sandbox/$(basename $input_file)', 'r') as f:\n    input_data = f.read()\n$code" > /home/executor/sandbox/code
      cp "$input_file" /home/executor/sandbox/
    fi
  elif [[ $cmd == "lua" ]]; then
    if [[ -z "$input_file" ]]; then
      echo "$code" > /home/executor/sandbox/code
    else
      echo -e "local file = io.open('/home/executor/sandbox/$(basename $input_file)', 'r')\nlocal input_data = file:read('*a')\nfile:close()\n$code" > /home/executor/sandbox/code
      cp "$input_file" /home/executor/sandbox/
    fi
  elif [[ $cmd == "node" ]]; then
    if [[ -z "$input_file" ]]; then
      echo "$code" > /home/executor/sandbox/code
    else
      echo -e "const fs = require('fs');\nconst input_data = fs.readFileSync('/home/executor/sandbox/$(basename $input_file)', 'utf8');\n$code" > /home/executor/sandbox/code
      cp "$input_file" /home/executor/sandbox/
    fi
  else
    echo "$code" > /home/executor/sandbox/code
  fi

  output=$(mktemp /home/executor/sandbox/tmp.XXXXXXXXXX)
  error=$(mktemp /home/executor/sandbox/tmp.XXXXXXXXXX)
  
  /home/executor/sandbox/$(basename $cmd) /home/executor/sandbox/code > "$output" 2> "$error"

  EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ]; then
    cat "$error"
    echo "EXECUTOR_ERROR"
    rm "$output" "$error"
    exit 1
  else
    cat "$output"
    rm "$output" "$error"
  fi
}

compile_and_execute_rust() {
  code=$1
  input_file=$2

  echo "$code" > /home/executor/sandbox/temp.rs
  cp "$input_file" /home/executor/sandbox/input

  COMPILE_RESULT=$(rustc /home/executor/sandbox/temp.rs -o /home/executor/sandbox/temp 2>&1)
  COMPILE_EXIT_CODE=$?
  if [ $COMPILE_EXIT_CODE -ne 0 ]; then
    echo "$COMPILE_RESULT"
    echo "EXECUTOR_ERROR"
    exit 1
  fi

  output=$(mktemp)
  error=$(mktemp)

  if [[ -z "$input_file" ]]; then
    /home/executor/sandbox/temp > "$output" 2> "$error"
  else
    /home/executor/sandbox/temp /home/executor/sandbox/input > "$output" 2> "$error"
  fi

  EXEC_RESULT=$(cat "$output")
  EXEC_EXIT_CODE=$?
  if [ $EXEC_EXIT_CODE -ne 0 ]; then
    cat "$error"
    echo "EXECUTOR_ERROR"
    rm "$output" "$error"
    exit 1
  else
    cat "$output"
    rm "$output" "$error"
  fi
}

case $LANGUAGE in
  "python")
    execute_code "python3" "$CODE" "$INPUT_FILE"
    ;;
  "lua")
    execute_code "lua" "$CODE" "$INPUT_FILE"
    ;;
  "javascript")
    execute_code "node" "$CODE" "$INPUT_FILE"
    ;;
  "rust")
    compile_and_execute_rust "$CODE" "$INPUT_FILE"
    ;;
  *)
    echo "Unsupported language EXECUTOR_ERROR"
    exit 1
    ;;
esac
