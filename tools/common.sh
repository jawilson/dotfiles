get_python_path() {
  if command -v python3 &> /dev/null; then
    echo "$(command -v python3)"
  elif command -v python2 &> /dev/null; then
    echo "$(command -v python2)"
  elif command -v python &> /dev/null; then
    echo "$(command -v python)"
  elif command -v py &> /dev/null; then
    if py -3 --version &> /dev/null; then
      echo "py -3"
    else
      echo "py"
    fi
  else
    echo ""
  fi
}
