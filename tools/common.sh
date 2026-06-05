is_windows_native() {
  if [ -n "$MSYSTEM" ]; then
    return 0
  else
    case "$(uname -s 2>/dev/null)" in
      CYGWIN*|MINGW*|MSYS*) return 0 ;;
      *) return 1 ;;
    esac
  fi
}

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
