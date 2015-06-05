# Encoding: utf-8
name             'elkstack'
maintainer       'Rackspace'
maintainer_email 'rackspace-cookbooks@rackspace.com'
license          'Apache 2.0'
description      'Installs/Configures elkstack'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '5.0.2'

depends 'apt'
depends 'build-essential'
depends 'chef-sugar'
depends 'cron', '~> 1.4.3'
depends 'elasticsearch', '~> 0.3'
depends 'htpasswd'
depends 'kibana_lwrp'
depends 'line'
depends 'logstash'
depends 'openssl'
depends 'newrelic_meetme_plugin'
depends 'nginx'
depends 'platformstack'
depends 'python'
depends 'rsyslog'
depends 'runit'
depends 'yum'

# Pinned down poise waiting for https://github.com/lusis/chef-kibana/pull/91
depends 'poise', '~> 1.0.12'
