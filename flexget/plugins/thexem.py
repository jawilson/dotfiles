# This plugin was taken from (https://github.com/z00nx/flexget-plugins)
# All original credit to z00nx, I have not yet changed anything

from __future__ import unicode_literals, division, absolute_import
import logging
import re

from flexget import plugin
from flexget.event import event
from flexget.utils import json, requests
from flexget.utils.soup import get_soup


log = logging.getLogger('thexem')
session = requests.Session()
#TODO: refactor/write the tvdb_id detection phase
#TODO: implement caching of XEM show mappings
#TODO: test further/catch more error conditions
#TODO: use map for the modification of entry fields


class PluginTheXEM(object):
    def validator(self):
        from flexget import validator
        root = validator.factory('dict')
        root.accept('choice', key='source', required=True).accept_choices(['scene', 'tvdb', 'anidb', 'rage'])
        root.accept('choice', key='destination', required=True).accept_choices(['scene', 'tvdb', 'anidb', 'rage'])
        return root

    @plugin.priority(109) # NOQA
    def on_task_metainfo(self, task, config): # NOQA
        if not config:
            return
        for entry in task.entries:
            if entry.get('series_id_type') == 'ep':
                if 'tvdb_id' in entry:
                    log.debug('The entry has a tvdb_id and will be used for mapping')
                else:
                    log.debug('The entry doesn\'t have tvdb_id, will check xem\'s list of shows')
                    try:
                        response = session.get('http://thexem.de/map/allNames?origin=tvdb&defaultNames=1&season=eq%s' % entry['series_season'])
                    except requests.RequestException as e:
                        log.debug('Error looking up show by name on thexem %s' % e)
                        continue
                    shownames = json.loads(response.content)
                    for tvdb_id in shownames['data'].keys():
                        if entry['series_name'] in shownames['data'][tvdb_id]:
                            entry['tvdb_id'] = tvdb_id
                            log.debug('The tvdb_id for %s is %s', entry['series_name'], entry['tvdb_id'])
                            break
                    if 'tvdb_id' not in entry:
                        log.debug('An tvdb_id was not found, will search the xem\'s site')
                        try:
                            response = session.get('http://thexem.de/search?q=%s' % entry['series_name'])
                        except requests.RequestException as e:
                            log.debug('Error searching for tvdb_id on thexem %s' % e)
                            continue
                        if response.url.startswith('http://thexem.de/xem/show/'):
                            soup = get_soup(response.content)
                            try:
                                entry['tvdb_id'] = soup.findAll('a', {'href': re.compile('^http://thetvdb.com/\?tab=series')})[0].next
                                log.debug('The tvdb_id for %s is %s', entry['series_name'], entry['tvdb_id'])
                            except:
                                pass
                        if 'tvdb_id' not in entry:
                            log.error('Unable to find a tvdb_id for %s, manually specify a tvdb_id using set', entry['series_name'])
                try:
                    response = session.get('http://thexem.de/map/all?id=%s&origin=tvdb' % entry['tvdb_id'])
                except requests.RequestException as e:
                    log.debug('Error getting episode map from thexem %s' % e)
                    continue
                episode_map = json.loads(response.content)
                if episode_map['result'] == 'success':
                    try:
                        for episode_entry in episode_map['data']:
                            if config['source'] not in episode_entry:
                                #log.warning('TheXEM does not provide unique data on %s - %s for source %s, skipping' % (entry['series_name'], entry['series_id'], config['source']))
                                continue
                            if config['destination'] not in episode_entry:
                                #log.warning('TheXEM does not provide unique data on %s - %s for destination %s, skipping' % (entry['series_name'], entry['series_id'], config['destination']))
                                continue
                            if episode_entry[config['source']]['season'] == entry['series_season'] and episode_entry[config['source']]['episode'] == entry['series_episode']:
                                log.debug('An XEM entry was found for %s, %s episode S%02dE%02d maps to %s episode S%02dE%02d' % (entry['series_name'], config['source'], entry['series_season'], entry['series_episode'], config['destination'], episode_entry[config['destination']]['season'], episode_entry[config['destination']]['episode']))
                                if 'description' in entry:
                                    entry['description'] = entry['description'].replace('Season: %s; Episode: %s' % (entry['series_season'], entry['series_episode']), 'Season: %s; Episode: %s' % (episode_entry[config['destination']]['season'], episode_entry[config['destination']]['episode']))
                                entry['series_season'] = episode_entry[config['destination']]['season']
                                entry['series_episode'] = episode_entry[config['destination']]['episode']
                                entry['series_id'] = 'S%02dE%02d' % (episode_entry[config['destination']]['season'], episode_entry[config['destination']]['episode'])
                                break
                    except:
                        log.error('Error in thexem plugin for entry %s (tvdb_id: %s)' %
                            (entry['title'], entry['tvdb_id']))
                        log.debug('Content was: %s' % response.content)



@event('plugin.register')
def register_plugin():
    plugin.register(PluginTheXEM, 'thexem', api_ver=2)
