import collectd
import urllib2
import time
import sys
import json

CONFIG = {}

def read_callback():
    get_metrics(CONFIG['URL'])

def get_metrics(url):
    try:
        response = urllib2.urlopen(url)
    except urllib2.HTTPError as e:
        collectd.error('nginx-plus plugin: Fetching stats failed: %s %s' % (e.code, e.reason))
        return

    stats = json.loads(response.read())

    submit_value({'type': 'generation', 'value': stats['generation']})

    # Simple sections
    for section in ['processes', 'connections', 'requests', 'ssl']:
        for key, value in stats[section].iteritems():
            submit_value({'type': section, 'type_instance': key, 'value': value})

    # These sections contain metrics per-zone/cache/upstream
    for section in ['caches', 'server_zones']:
        # config_name is the name of a particular cache config or server_zone
        for config_name, metrics in stats[section].iteritems():
            for key, metrics in metrics.iteritems():
                if type(metrics) == dict: # Go deeper
                    for subkey, value in metrics.iteritems():
                        submit_value({'type': section, 'type_instance': key + '.' + subkey, 'plugin_instance': config_name, 'value': value})
                else:
                    submit_value({'type': section, 'type_instance': key, 'value': metrics})

    # Each upstream configuration contains one or more peers (servers) containing metrics
    for config_name, upstream in stats['upstreams'].iteritems():
        for peer in upstream['peers']:
            plugin_instance = config_name + '.' + peer.pop('server')
            for key, metrics in peer.iteritems():
                if type(metrics) == dict: # Go deeper
                    for subkey, value in metrics.iteritems():
                        submit_value({'type': 'upstreams', 'type_instance': key + '.' + subkey, 'plugin_instance': plugin_instance, 'value': value})
                else:
                    submit_value({'type': 'upstreams', 'type_instance': key, 'plugin_instance': plugin_instance, 'value': metrics})


def configure_callback(conf):
    for node in conf.children:
        if node.key == 'URL':
            CONFIG['URL'] = node.values[0]
            collectd.notice('nginx-plus plugin: Setting nginx-plus stats URL to %s' % node.values[0] )
        else:
            collectd.warning('nginx-plus plugin: Unknown config key: %s.' % node.key )

def submit_value(value_dict):
    collectd_type = value_dict['type']
    type_instance = value_dict.get('type_instance', None)
    plugin_instance = value_dict.get('plugin_instance', None)
    value = value_dict['value']

    if isinstance(value, (bool,str,unicode)):
        print "Can't submit value '%s' of type '%s'" % (value, type(value))
        return None

    v = collectd.Values(type='gauge')
    v.plugin = 'nginx_plus'
    v.type = prefix_type(collectd_type)
    if type_instance:
        v.type_instance = type_instance
    if plugin_instance:
        v.plugin_instance = plugin_instance
    v.values = [value]
    collectd.warning('%s' % v)
    v.dispatch()

# Prefix types that are already reserved in types.db with nginx_
def prefix_type(type):
    return {'connections': 'nginx_connections'}.get(type, type)



collectd.register_config(configure_callback)
collectd.register_read(read_callback)
