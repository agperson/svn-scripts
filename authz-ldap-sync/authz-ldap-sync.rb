#!/usr/bin/env ruby

require 'rubygems'
require 'ldap'
require 'iniparse'
require 'yaml'

# Load configuration from YAML file
config = YAML.load_file(File.join(File.dirname(__FILE__), 'config.yaml'))
ldap = LDAP::Conn.new(config['ldap']['host'], config['ldap']['port'])

files = Dir["#{config['directory']}/*.ini"]
if files.nil?
  puts "Directory #{config['directory']} is empty or unreadable, exiting."
  exit
end

files.each do |path|
  # Basic permission checking
  if not File.readable?(path)
    puts "File #{path} is not readable, skipping."
    break
  elsif not File.writable?(path)
    puts "File #{path} is not writable, skipping."
    break
  end

  puts "Parsing file #{path}"
  file = IniParse.parse(File.read(path))
  file['groups'].each do |group|
    puts "- Updating group #{group.key}"
    filter = "(cn=#{group.key})"
    attrs = "memberUid"
    ldap.search(config['ldap']['base'], LDAP::LDAP_SCOPE_SUBTREE, filter, attrs) do |entry|
      members = entry.vals('memberUid')
      members.delete_if { |m| m =~ /^uid=/ }
      members = members.collect { |m| "#{m}@FAS.HARVARD.EDU" }
      group.value = members.join(', ')
    end
  end

  puts "Saving file"
  file.save(path)
end
