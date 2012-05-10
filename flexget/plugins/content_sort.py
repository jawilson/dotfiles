import logging
import posixpath
from fnmatch import fnmatch
from flexget.plugin import register_plugin, priority

log = logging.getLogger('content_sort')


class FilterContentSort(object):
    """
    Set the movedone attribute based on torrent contents. Earlier defined types take predence

    Example:
    content_sort:
      '*.rar': '/path/to/move'
      '*.mkv': '/other/path'
    """

    def validator(self):
        from flexget import validator
        config = validator.factory('dict')
        config.accept_any_key('any')
        return config

    def process_entry(self, feed, entry, config):
        if 'content_files' in entry:
            files = entry['content_files']
            log.debug('%s files: %s' % (entry['title'], files))

            for mask, path in config.items():
                log.debug('Checing for: %s' % mask)
                for file in files:
                    log.debug('\t in: %s' % file)
                    if fnmatch(file, mask):
                        conf = {'movedone': path }
                        log.debug('adding set: info to entry:\'%s\' %s' % (entry['title'], conf))
                        entry.update(conf)

    def parse_torrent_files(self, entry):
        if 'torrent' in entry and 'content_files' not in entry:
            files = [posixpath.join(item['path'], item['name']) for item in entry['torrent'].get_filelist()]
            if files:
                entry['content_files'] = files

    @priority(149)
    def on_feed_modify(self, feed):
        if feed.manager.options.test or feed.manager.options.learn:
            log.info('Plugin is partially disabled with --test and --learn because content filename information may not be available')
            return
        config = feed.config.get('content_sort')
        for entry in feed.accepted:
            # TODO: I don't know if we can parse filenames from nzbs, just do torrents for now
            self.parse_torrent_files(entry)
            self.process_entry(feed, entry, config)

register_plugin(FilterContentSort, 'content_sort')
