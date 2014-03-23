#!/usr/bin/env ruby
# Daemonizer script for sync-kicker. Control with [start|stop|restart]

require 'rubygems'
require 'daemons'
Daemons.run('sync-kicker.rb', :dir_mode => :normal, :dir => '/var/run') do
end
