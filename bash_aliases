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
alias "flexget"="~/Flexget/bin/flexget --logfile ~/Flexget/flexget.log"
alias "flexget-daemon"="/home/deluge/Flexget/bin/flexget --logfile /home/deluge/.flexget/flexget.log daemon"
alias "flexget-cron"="/usr/bin/time -o /home/deluge/.flexget/flexget.log -a -f 'Run time was %E' /home/deluge/Flexget/bin/flexget -c /home/deluge/.flexget/config.yml execute --cron"
alias "flexget-sort-tv"="~/Flexget/bin/flexget --logfile /home/deluge/.flexget/flexget-sorting.log --debug -c /home/deluge/.flexget/sorting.yml execute --task Sort_Unpacked_TV_Shows --disable-advancement"
alias "flexget-sort-premieres"="~/Flexget/bin/flexget --logfile /home/deluge/.flexget/flexget-sorting.log --debug -c /home/deluge/.flexget/sorting.yml execute --task Sort_Unpacked_TV_Premieres --disable-advancement"
alias "flexget-sort-movies"="~/Flexget/bin/flexget --logfile /home/deluge/.flexget/flexget-sorting.log --debug -c /home/deluge/.flexget/sorting.yml execute --task Sort_Unpacked_Movies"

# ack-grep
alias "ack"="ack-grep"

# git
alias gdiff='git diff --no-index'
