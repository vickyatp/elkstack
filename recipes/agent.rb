# Encoding: utf-8
#
# Cookbook Name:: elkstack
# Recipe:: agent
#
# Copyright 2014, Rackspace
#

# base stack requirements for an all-in-one node
include_recipe 'elkstack::_base'
agent_name = node['elkstack']['config']['logstash']['agent_name']
agent_data = node['logstash']['instance'][agent_name]

# find central servers
include_recipe 'elasticsearch::search_discovery'
elk_nodes = node['elasticsearch']['discovery']['zen']['ping']['unicast']['hosts']

# configure logstash for forwarding
logstash_instance agent_name do
  action :create
end

# platformstack needs to be able to turn this off
enable_attr = node.deep_fetch('platformstack', 'elkstack_logging', 'enabled')
logging_enabled = !enable_attr.nil? && enable_attr # ensure this is binary logic, not nil
logstash_service agent_name do
  action :enable
  # enable this if the flag is on
  only_if { logging_enabled }
end

# terrible workaround RE: http://stackoverflow.com/questions/25792383/notify-service-defined-in-included-lwrp-recipe
service "logstash_#{agent_name}" do
  action :nothing
  only_if { logging_enabled }
end

my_templates = {
  'input_syslog'         => 'logstash/input_syslog.conf.erb',
  'output_stdout'        => 'logstash/output_stdout.conf.erb'
}

template_variables = {
  output_lumberjack_hosts: elk_nodes.split(','),
  output_lumberjack_port: 5960,
  input_syslog_host: '127.0.0.1',
  input_syslog_port: 5959,
  chef_environment: node.chef_environment
}

include_recipe 'elkstack::_secrets'
unless node.run_state['lumberjack_decoded_certificate'].nil? || node.run_state['lumberjack_decoded_certificate'].nil?
  my_templates['output_lumberjack'] = 'logstash/output_lumberjack.conf.erb'
  template_variables['output_lumberjack_ssl_certificate'] = "#{node['logstash']['instance_default']['basedir']}/lumberjack.crt"
  # template_variables['output_lumberjack_ssl_key'] = "#{node['logstash']['instance_default']['basedir']}/lumberjack.key"
end

logstash_pattern agent_name do
  action [:create]
end

logstash_config agent_name do
  templates_cookbook 'elkstack'
  templates my_templates
  variables(template_variables)
  notifies :restart, "logstash_service[#{agent_name}]", :delayed
  action [:create]
end

# configure any additional templates
node['elkstack']['config']['additional_logstash_templates'].each do |logging_template|
  template logging_template['name'] do
    source logging_template['source']
    cookbook logging_template['cookbook']
    user agent_data['user']
    group agent_data['group']
    path "#{node['logstash']['instance_default']['basedir']}/agent/etc/conf.d/#{logging_template['name']}"
    variables logging_template['variables']
    notifies 'restart', "service[logstash_#{agent_name}]", 'delayed'
  end
end

# see attributes, will forward to logstash agent on localhost
include_recipe 'rsyslog::client'
