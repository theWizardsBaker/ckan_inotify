#!/usr/bin/ruby

require 'rubygems'
require 'inotify'
require './ckan_shuttle_users.rb'

# Create the notifier
notifier = INotify::Notifier.new

# # Watch for any file in the directory being added
# # or moved into the directory.
# notifier.watch("path/to/directory", :create, :moved_to) do |event|
#   # Create the file
#   out_file = File.new("demo.txt", "a")
#   # The #name field of the event object contains the name of the affected file
#   out_file.puts "Remove #{event.name}, path: #{event.}"
#   # Close the output file
#   out_file.close
# end

# # Watch for any file in the directory being deleted
# # or moved out of the directory.
# notifier.watch("path/to/directory", :delete, :moved_from) do |event|
#   # The #name field of the event object contains the name of the affected file
#   puts "#{event.name} is no longer in the directory!"
# end

# watch for changes to users
ckan_watch_file = '/var/www/exports/xml/users.xml'
notifier.watch(ckan_watch_file, :modify) do |event|
	load_users(ckan_watch_file)
end

# Nothing happens until you run the notifier!
notifier.run

