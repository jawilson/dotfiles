
"""Filler plugin that does nothing."""
from __future__ import unicode_literals, division, absolute_import
import re
import logging

from flexget import plugin
from flexget.entry import Entry
from flexget.event import event

log = logging.getLogger('filler')


class Filler(object):
    def validator(self):
        from flexget import validator
        return validator.factory('any')

    def on_task_input(self, task, config):
        task.no_entries_ok = True
        entry = Entry(title="###FILLER###", url="file:///dev/null")
        entry.reject()
        return [entry]

    def on_task_output(self, task, config):
        pass

    def search(self, entry, config=None):
        pass

@event('plugin.register')
def register_plugin():
    plugin.register(Filler, 'filler', groups=['search'], api_ver=2)
