# ls
alias "ls"="ls --color -h --group-directories-first"
alias "ll"="ls -l"

# grep
alias "grep"="grep --color"

# flexget
alias "flexget"="~/Flexget/bin/flexget --logfile ~/Flexget/flexget.log"
alias "flexget-cron"="/usr/bin/time -o /home/deluge/.flexget/flexget.log -a -f 'Run time was %E' /home/deluge/Flexget/bin/flexget -c /home/deluge/.flexget/config.yml --cron"
alias "flexget-sort-tv"="~/Flexget/bin/flexget --logfile /home/deluge/.flexget/flexget-sorting.log -c /home/deluge/.flexget/sorting.yml --task Sort_Unpacked_TV_Shows --debug --disable-advancement"
alias "flexget-sort-premieres"="~/Flexget/bin/flexget --logfile /home/deluge/.flexget/flexget-sorting.log -c /home/deluge/.flexget/sorting.yml --task Sort_Unpacked_TV_Premieres --debug --disable-advancement"
alias "flexget-sort-movies"="~/Flexget/bin/flexget --logfile /home/deluge/.flexget/flexget-sorting.log -c /home/deluge/.flexget/sorting.yml --task Sort_Unpacked_Movies --debug"

# ack-grep
alias "ack"="ack-grep"

# git
alias git-pretty-graph="git log --graph --pretty=oneline --abbrev-commit --decorate"
