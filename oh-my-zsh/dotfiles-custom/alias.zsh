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
alias "flexget"="$HOME/src/flexget/bin/flexget"
alias "flexget-log-tail"="tail -n 300 $HOME/.flexget/flexget.log | less "
alias "flexget-sort-tv"="sudo -u debian-deluged $HOME/src/flexget/bin/flexget -L verbose -c $HOME/.flexget/sorting.yml -l $HOME/.flexget/flexget-sorting.log execute --task Sort_Unpacked_TV_Shows --disable-advancement"
alias "flexget-sort-premieres"="sudo -u debian-deluged $HOME/src/flexget/bin/flexget -L verbose -c $HOME/.flexget/sorting.yml -l $HOME/.flexget/flexget-sorting.log execute --task Sort_Unpacked_TV_Premieres --disable-advancement"
alias "flexget-sort-movies"="sudo -u debian-deluged $HOME/src/flexget/bin/flexget -L verbose -c $HOME/.flexget/sorting.yml -l $HOME/.flexget/flexget-sorting.log execute --task Sort_Unpacked_Movies"
alias "flexget-sort-log-tail"="tail -n 300 $HOME/.flexget/flexget-sorting.log | less "

# ack-grep
alias "ack"="ack-grep"

# git
alias gdiff='git diff --no-index'
alias gitroot='cd "$(git rev-parse --show-toplevel)"'

#awk
alias dedup="awk '!seen[$0]++'"
