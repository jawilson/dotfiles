import logging
from datetime import timedelta, datetime
from math import fabs
from flexget.plugin import register_plugin, priority
from flexget.utils.log import log_once

log = logging.getLogger('my_movie_filter')


class MyMovieFilter(object):
    """
       Filters entries based on some crazy custom rules
    """
    
    def __init__(self):
        self.required_fields = [
                'imdb_url', 'imdb_languages', 'imdb_votes', 'imdb_votes', 'rt_id', 'rt_releases',
                'rt_genres', 'rt_critics_rating', 'rt_audience_rating', 'rt_critics_score',
                'rt_audience_score', 'rt_average_score'
                ]
        self.languages = ['english']
        self.max_accept_ages = [(2,'new'), (10, 'recent'), (25, 'old'), (40, 'classic')]

        self.imdb_genres_reject = ['musical']
        self.imdb_single_genres_strict = {'drama': 95, 'romance': 97, 'animation': 90}
        self.imdb_genres_strict = {'drama': 85, 'romance': 85, 'documentary': 83, 'horror': 90, 'animation': 86, 'family': 85}
        self.imdb_genres_accept_except = ['animation', 'family', 'horror', 'romance']
        self.imdb_genres_accept = {'action': 62, 'sci-fi': 62, 'war': 62, 'crime': 62, 'comedy': 65, 'history': 70, 'mystery': 72, 'thriller': 72}

        self.rt_genres_reject = ['Musical & Performing Arts', 'Anime & Manga', 'Faith & Spirituality', 'Gay & Lesbian']
        self.rt_single_genres_strict = {'Drama': 95, 'Romance': 97, 'Art House & International Movies': 99}
        self.rt_genres_strict = {'Drama': 85, 'Romance': 85, 'Documentary': 83, 'Horror': 90, 'Animation': 86, 'Special Interest': 89, 'Kids & Family': 85, 'Art House & International Movies': 80}
        self.rt_genres_accept_except = ['Animation', 'Kids & Family', 'Horror', 'Romance', 'Art House & International Movies']
        self.rt_genres_accept = {'Action & Adventure': 60, 'Science Fiction & Fantasy': 62, 'Comedy': 65, 'Mystery & Suspense': 72}

    def validator(self):
        from flexget import validator
        return validator.factory('boolean')


    def check_fields(self, feed, entry):
        for field in self.required_fields:
            if not entry.get(field) and entry.get(field) != 0:
                feed.reject(entry, 'Required field %s is not present' % field)
                return False
        return True


    @priority(-255) # Make filter run very last
    def on_feed_filter(self, feed, config):
        log.debug('Running custom filter')
        for entry in feed.entries:
            force_accept = False
            reasons = []
            
            if not self.check_fields(feed, entry):
                continue

            # Don't allow straight to DVD flicks
            if not entry['rt_releases'].get('theater', False):
                feed.reject(entry, 'No theater release date')
                continue

            # Enforce languages
            if entry['imdb_languages'][0] not in self.languages:
                feed.reject(entry, 'primary language not in %s' % self.languages)
                continue

            # Reject some genrces outright
            if any(genre in self.imdb_genres_reject for genre in entry['imdb_genres']):
                feed.reject(entry, 'imdb genres')
                continue
            if any(genre in self.rt_genres_reject for genre in entry['rt_genres']):
                feed.reject(entry, 'rt genres')
                continue

            # Get the age classification of the movie
            entry_age = ''
            for years,age in sorted(self.max_accept_ages):
                if entry['rt_releases']['theater'] > datetime.now() - timedelta(days=(365*years)):
                    log.debug('Age class is %s' % age)
                    entry_age = age
                    break

            # Make sure all scores are reliable
            if (age in ['new', 'recent'] and not entry['rt_critics_consensus']) or entry['rt_critics_score'] < 0 or entry['rt_audience_score'] < 0 or entry['imdb_votes'] < 6000 or entry['imdb_score'] == 0:
                feed.reject(entry, 'Unreliable scores (rt_critics_consensus: %s, rt_critics_score: %s, rt_audience_score: %s, imdb_votes: %s, imdb_score: %s)' % 
                    (('filled' if entry['rt_critics_consensus'] else None) , entry['rt_critics_score'], entry['rt_audience_score'], entry['imdb_votes'], entry['imdb_score'])
                )
                continue

            # Determine which score to use
            if entry['rt_audience_rating'] == 'Spilled':
                log.debug('Audience doesn\'t approve, using audience score')
                score = entry['rt_audience_score']
            elif entry['rt_critics_score'] - entry['rt_audience_score'] > 20:
                log.debug('Critics and audience don\'t agree, using critics')
                score = entry['rt_critics_score']
            elif entry['rt_audience_score'] - entry['rt_critics_score'] > 20:
                log.debug('Critics and audience don\'t agree, using audience')
                score = entry['rt_audience_score']
            else:
                score = entry['rt_average_score']
                
            log.debug('Using score: %s' % score)

            # Score filters that depend on age
            if entry_age == 'new' or entry_age == 'recent':
                min_score = 70;
            elif entry_age == 'old':
                min_score = 75;
            elif entry_age == 'classic':
                min_score = 85;
                if entry['rt_critics_rating'] != 'Certified Fresh':
                    reasons.append('%s movie (%s != Certified Fresh)' % (entry_age, entry['rt_critics_rating']))
            else:
                min_score = 101
                reasons.append('Theater release date too far in the past')
                
            log.debug('Minimum acceptable score is %s' % min_score)
            if score < min_score:
                reasons.append('%s movie (score %s < %s)' % (entry_age, score, min_score))

            # A bunch of imdb genre filters
            strict_reasons = []
            allow_force_accept = not any(genre in self.imdb_genres_accept_except for genre in entry['imdb_genres'])
            for genre in entry['imdb_genres']:
                if len(entry['imdb_genres']) == 1:
                    min_score = self.imdb_single_genres_strict.get(genre, None)
                    if min_score and score < min_score:
                            reasons.append('imdb single genre strict (%s and %s < %s)' % (genre, score,min_score))
                min_score = self.imdb_genres_strict.get(genre, None)
                if min_score and (score < min_score or entry['rt_critics_rating'] != 'Certified Fresh'):
                        strict_reasons.append('%s and %s < %s' % (genre, score, min_score))
                if allow_force_accept:
                    min_score = self.imdb_genres_accept.get(genre, None)
                    if min_score and score > min_score:
                        log.debug('Accepting because of imdb genre accept (%s and %s < %s)' % (genre,score,min_score))
                        force_accept = True
                        break
            if strict_reasons:
                reasons.append('imdb genre strict (%s)' %  (', '.join(strict_reasons)))

            # A bunch of rt genre filters
            strict_reasons = []
            allow_force_accept = not any(genre in self.rt_genres_accept_except for genre in entry['rt_genres'])
            for genre in entry['rt_genres']:
                if len(entry['rt_genres']) == 1:
                    min_score = self.rt_single_genres_strict.get(genre, None)
                    if min_score and score < min_score:
                            reasons.append('rt single genre strict (%s and %s < %s)' % (genre,score,min_score))
                min_score = self.rt_genres_strict.get(genre, None)
                if min_score and (score < min_score or entry['rt_critics_rating'] != 'Certified Fresh'):
                        strict_reasons.append('%s and %s < %s' % (genre, score, min_score))
                if allow_force_accept:
                    min_score = self.rt_genres_accept.get(genre, None)
                    if min_score and score > min_score:
                        log.debug('Accepting because of rt genre accept (%s and %s < %s)' % (genre,score,min_score))
                        force_accept = True
                        break
            if strict_reasons:
                reasons.append('rt genre strict (%s)' %  (', '.join(strict_reasons)))


            if reasons and not force_accept:
                msg = 'Didn\'t accept `%s` because of rule(s) %s' % \
                    (entry.get('rt_name', None) or entry['title'], ', '.join(reasons))
                if feed.manager.options.debug:
                    log.debug(msg)
                else:
                    if feed.manager.options.quiet:
                        log_once(msg, log)
                    else:
                        log.info(msg)
            else:
                log.debug('Accepting %s' % (entry['title']))
                feed.accept(entry)


register_plugin(MyMovieFilter, 'my_movie_filter', api_ver=2)
