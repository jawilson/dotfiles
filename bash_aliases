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
alias "flexget"="~/src/flexget/bin/flexget --logfile ~/src/flexget/flexget.log"
alias "flexget-daemon"="/home/jawilson/src/flexget/bin/flexget --logfile /home/jawilson/.flexget/flexget.log daemon"
alias "flexget-cron"="/usr/bin/time -o /home/jawilson/.flexget/flexget.log -a -f 'Run time was %E' /home/jawilson/src/flexget/bin/flexget -c /home/jawilson/.flexget/config.yml execute --cron"
alias "flexget-sort-tv"="~/src/flexget/bin/flexget --logfile /home/jawilson/.flexget/flexget-sorting.log --debug -c /home/jawilson/.flexget/sorting.yml execute --task Sort_Unpacked_TV_Shows --disable-advancement"
alias "flexget-sort-premieres"="~/src/flexget/bin/flexget --logfile /home/jawilson/.flexget/flexget-sorting.log --debug -c /home/jawilson/.flexget/sorting.yml execute --task Sort_Unpacked_TV_Premieres --disable-advancement"
alias "flexget-sort-movies"="~/src/flexget/bin/flexget --logfile /home/jawilson/.flexget/flexget-sorting.log --debug -c /home/jawilson/.flexget/sorting.yml execute --task Sort_Unpacked_Movies"

# ack-grep
alias "ack"="ack-grep"

# git
alias gdiff='git diff --no-index'
