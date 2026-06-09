# open up emacs in client mode, defaulting to current dir
emacs() {
  if [ $# -eq 0 ]; then
    emacsclient -c .
  else
    emacsclient -c "$@"
  fi
}
