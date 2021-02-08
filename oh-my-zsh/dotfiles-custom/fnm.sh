# ZSH
autoload -U add-zsh-hook

# place default node version under $HOME/.node-version
load-nvmrc() {
  DEFAULT_NODE_VERSION=`cat $HOME/.node-version`
  if [[ -f .nvmrc && -r .nvmrc ]]; then
    fnm use
  elif [[ `node -v` != $DEFAULT_NODE_VERSION ]]; then
    echo Reverting to node from "`node -v`" to "$DEFAULT_NODE_VERSION"
    fnm use $DEFAULT_NODE_VERSION
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc
