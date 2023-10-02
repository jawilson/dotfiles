# ls
alias ls='ls --color=auto -h --group-directories-first'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# grep
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# flexget
alias flexget="docker-compose -f /media/raid/flexget/docker-compose.yml exec flexget flexget -c /config/config.yml -l /dev/null"
alias fgsl="flexget series list"
alias fgss="flexget series show"
alias fgsf="flexget series forget"

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

# HomeAssistant
alias certbot-renew="docker-compose -f /media/raid/home-assistant/docker-compose.yml.letsencrypt up"

# acme.sh
alias acme.sh="docker-compose -f /media/raid/acme/docker-compose.yml exec acme"

# docker
alias dlg="echo $CR_PAT | docker login ghcr.io -u jawilson --password-stdin"
