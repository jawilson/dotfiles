# dotfiles
alias dotfiles='git --git-dir=$DOTFILES_DIR/.git --work-tree=$DOTFILES_DIR'

# ls
alias ls='ls --color=auto -h --group-directories-first'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# grep
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ack-grep
alias "ack"="ack-grep"

# git
alias gdiff='git diff --no-index'
alias gitroot='cd "$(git rev-parse --show-toplevel)"'
alias gbdag='git fetch -p && for branch in $(git for-each-ref --format "%(refname) %(upstream:track)" refs/heads | awk '\''$2 == "[gone]" {sub("refs/heads/", "", $1); print $1}'\'' | tr "\n" " "); do git branch -D $branch; done'

# awk
alias dedup="awk '!seen[$0]++'"

# plex
alias plexup="sudo sh -c \"rm -rf /tmp/pms && install -d /tmp/pms && wget --content-disposition https://plex.tv/downloads/latest/1\?channel\=8\&build\=linux-ubuntu-x86_64\&distro\=ubuntu\&X-Plex-Token\=ZYD6a4uHqssyqpUnKy8d --directory-prefix=/tmp/pms/ && find '/tmp/pms/' -type f | head -1 | xargs -I{} dpkg -i '{}' && rm -rf /tmp/pms\""
alias plexpyup="docker pull linuxserver/plexpy && if docker stop plexpy >/dev/null 2>&1; then  docker rm plexpy >/dev/null; fi && \
docker run \
  --name=plexpy -v /media/raid/plexmediaserver/plexpy:/config --restart always \
  -v \"/media/raid/plexmediaserver/Library/Application Support/Plex Media Server/Logs\":/logs:ro \
  -e PGID=115 -e PUID=110 \
  -e TZ=America/New_York \
  -p 8181:8181 \
  -d linuxserver/plexpy"

# docker
alias docker-compose="docker compose"
alias dlggh="get-cred-password ghcr.io | docker login ghcr.io -u jawilson --password-stdin"
alias dlgaws="aws ecr get-login-password | docker login --username AWS --password-stdin \$(aws sts get-caller-identity --query Account --output text).dkr.ecr.\$(aws configure get region).amazonaws.com"
alias dlga="dlgaws; dlggh"
