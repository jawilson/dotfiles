**FLEXGET UPDATE:** I have moved my flexget configuration to [jawilson/flexget-config](https://github.com/jawilson/flexget-config) since it's not necessary on all of my devices. Sorry for any inconvienience that may cause you.

# Jeff Wilson Dot Files

These are config files to set up a system the way I like it.

## Installation

    git clone https://github.com/jawilson/dotfiles.git ~/.dotfiles
    cd ~/.dotfiles
    ./install.sh

`install.sh` installs [mise](https://mise.jdx.dev) if needed and links the files declared in `mise.toml` into `$HOME`. After changing `mise.toml`, run `mise dot apply` from the repository to update the links.
