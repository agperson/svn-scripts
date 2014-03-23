#!/usr/bin/ruby

require 'rubygems'
require 'socket'
require 'eventmachine'
require 'logger'
require 'yaml'

# Load configuration from YAML file
$config = YAML.load_file(File.join(File.dirname(__FILE__), 'config.yaml'))

$logger = Logger.new($config[:logpath] + "/sync-kicker.log")
$logger.datetime_format = "%Y-%m-%d %H:%M:%S"

class SVNKicker < EventMachine::Connection
  def receive_data(data)
    # Obtain IP address and port of sender so we can log it
    port, ip = Socket.unpack_sockaddr_in(get_peername)
    $logger.info "Kick received from #{ip}:#{port}"

    # Split out data components, which are space-seperated.  Rev is optional
    # and only used for copy-revprops.
    action, space, repo, rev = data.split(' ')

    # This is the proc to perform sync actions, which is passed into defer
    run_sync = Proc.new do
      logfile = $config[:logpath] + "/sync-#{space}-#{repo}.log"

      # Make sure we are not already running a sync action for this space/repo
      if not system("ps -ww -u #{$config[:user]} u | grep ' sync.*#{space}/#{repo}$' >/dev/null") then
        # Obtain a Kerberos ticket if necessary
        `klist -s || kinit -k -t #{$config[:keytab]} #{$config[:user]}/svnsync 2>&1 1>>#{logfile}`

        # Start the sync process
        `echo "Starting sync at $(date)" >> #{logfile}`
        `svnsync #{$config[:syncopts]} sync https://#{$config[:host]}/#{space}/#{repo} 2>&1 1>>#{logfile}`
        `echo "Finishing sync at $(date)" >> #{logfile}`
      else
        `echo "Ignoring sync request at $(date) because another sync is already in progress." >> #{logfile}`
      end
    end # run_sync

    # And this is the proc to perform copy-revprops actions, used by defer
    run_revprops = Proc.new do
      logfile = $config[:logpath] + "/revprops-#{space}-#{repo}.log"

      # Make sure we are not already running a sync action for this space/repo
      if not system("ps -ww -u #{$config[:user]} u | grep ' copy-revprops.*#{space}/#{repo}$' >/dev/null") then
        # Obtain a Kerberos ticket if necessary
        `klist -s || kinit -k -t #{$config[:keytab]} #{$config[:user]}/svnsync 2>&1 1>>#{logfile}`

        # Start the copy-revprops process
        `echo "Starting copy-revprops at $(date)" >> #{logfile}`
        `svnsync #{$config[:syncopts]} copy-revprops https://#{$config[:host]}:#{$config[:port]}/#{space}/#{repo} #{rev} 2>&1 1>>#{logfile}`
        `echo "Finishing copy-revprops at $(date)" >> #{logfile}`
      else
        `echo "Ignoring copy-revprops request at $(date) because another copy-revprops is already in progress." >> #{logfile}`
      end
    end # run_revprops

    # Validate each component and spit off helper if validation succeeds.
    if action == "copy-revprops" and rev.to_i and space =~ /^[a-zA-Z0-9_-]+/ and repo =~ /^[a-zA-Z0-9_-]+/ then
      $logger.info " - Data validates, calling copy-revprops helper with values:"
      $logger.info "   space: #{space}, repo: #{repo}, rev: #{rev}"
      EventMachine.defer(run_revprops)
    elsif action == "sync" and space =~ /^[a-zA-Z0-9_-]+/ and repo =~ /^[a-zA-Z0-9_-]+/ then
      $logger.info " - Data validates, calling sync helper with values:"
      $logger.info "   space: #{space}, repo: #{repo}"
      EventMachine.defer(run_sync)
    else
      $logger.warn " - Data does not validate (#{data}), aborting."
    end
  end # receive_data
end # SVNKicker

EventMachine.run do
  $logger.info "Subversion sync kicker listening on #{$config[:host]} port #{$config[:port]}..."
  EventMachine.open_datagram_socket $config[:host], $config[:port], SVNKicker
end
