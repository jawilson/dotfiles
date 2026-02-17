# We're using OMZ for our git prompt, this file exists so that Git Bash on Windows doesn't do anything.

# /etc/profile.d/git-prompt.sh still tryies to run shopt
function shopt() { :; }
