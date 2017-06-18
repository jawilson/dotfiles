from __future__ import unicode_literals, division, absolute_import
from builtins import *  # noqa pylint: disable=unused-import, redefined-builtin

import logging

from flexget import plugin
from flexget.event import event
from flexget.manager import Session

try:
    from flexget.plugins.filter.series import (Series, normalize_series_name, shows_by_exact_name,
                                               add_series_entity)
except ImportError:
    raise plugin.DependencyError(issued_by='series_add', missing='series',
                                 message='series_add plugin need series plugin to work')

log = logging.getLogger('series_add')


class OutputSeriesAdd(object):
    schema = {'type': 'boolean'}

    def on_task_output(self, task, config):
        if not config:
            return
        with Session() as session:
            for entry in task.accepted:
                if 'series_name' in entry and 'series_id' in entry:
                    series_name = entry['series_name'].replace(r'\!', '!')
                    normalized_name = normalize_series_name(series_name)
                    series = shows_by_exact_name(normalized_name, session)
                    if not series:
                        log.info('Series not yet in database, adding `%s`' % series_name)
                        series = Series()
                        series.name = series_name
                        session.add(series)
                    else:
                        series = series[0]
                    try:
                        add_series_entity(session, series, entry['series_id'],
                                          quality=entry['quality'])
                    except ValueError as e:
                        log.warn(e.args[0])
                    else:
                        log.info('Added entity `%s` to series `%s`.' % (entry['series_id'], series.name.title()))


@event('plugin.register')
def register_plugin():
    plugin.register(OutputSeriesAdd, 'series_add', api_ver=2)
