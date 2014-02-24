# [Flexget](http://www.flexget.com) Configuration Files

Created by: Jeff Wilson <jeff@jeffalwilson.com>
Available from: https://github.com/jawilson/dotfiles

I try to keep this configuration in sync with whatever version my fork of Flexget (available at https://github.com/jawilson/Flexget) is at.

For various reasons I've moved some settings into a private subfolder. The files are:
* private/global.yml
* private/movie-queue.yml
* private/movies-discover.yml
* private/movies-global.yml
* private/tv-global.yml

These files are not necessary to use this cofiguration, simply remove the 'include' plugin references and you should be fine. You'll also want to check for a few places that I've commented out sections that I've moved to these config files. I've also added redacted versions of the private files to reference if you'd like to do the same.

## Rar-unpacking

My entire setup results in a single video file (.mkv, .mp4, etc) in the final destination with a nice name regardless if it's packed in a rar or not.
Here's the gist of how it works:
  1. Flexget accepts the torrent regardless if it's a rar-pack or not
  2. My custom content_sort plugin changes the move_done value if the torrent contains a .rar
  3. The torrent is added to Deluge
  4. Deluge is configured with the [Execute](http://dev.deluge-torrent.org/wiki/Plugins/Execute) plugin to run my deluge_torrent_complete script (also available in this repository) when any torrent is done downloading
  5. deluge_torrent_complete checks if the torrent is located in the directory we set in step #2, if not it skips to the last step
  6. deluge_torrent_complete unpacks the first .rar file it finds in the torrent to a 'staging' location
  7. deluge_torrent_complete calls flexget with a completely separate config, 'sorting.yml' (also available in this repository)
  8. The 'sorting.yml' config checks for files in the 'staging' location from step #6 and renames and moves the files to their appropriate final location
  9. deluge_torrent_complete tells my XBMC server to update the library (scan for new files)


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/jawilson/dotfiles/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
