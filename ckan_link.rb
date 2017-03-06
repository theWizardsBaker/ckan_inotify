#!/usr/bin/ruby -w
# create links to ckan files
require 'securerandom'
require 'optparse'

def sanitize_filename(filename)
    filename.strip!
    filename.gsub!(/^.*(\\|\/)/, '')
    # Strip out the non-ascii character
    filename.gsub!(/[^0-9A-Za-z.\-]/, '_')
end

# location we're exporting
WEB_STORAGE_LOCATION = "/array2/web_publish/"
options = {}

OptionParser.new do |opts|
    # write example
    opts.banner = "Usage: example.rb [options] file"
    # linked file name
    opts.on("-l", "--link-name=val", "Name of Linked File") { |val| options[:link] = val }
    # create link output file
    options[:link_file] = true
    opts.on("-o", "--output-file", "Create Output File") { options[:link_file] = false }
    # output file location
    opts.on("-d", "--ouput-dest=val", "Output File Location") { |val| options[:file_location] = val }
end.parse!

begin
    ARGV.each do |arg|
        # generate our random dir name
        random_string = SecureRandom.hex

        # pars ARGs
        file_name = arg || nil

        # insure a file was specified
        raise "A file name is required" if file_name.nil? or file_name.empty?

        # check file readability
        raise "#{file_name} is not readable" unless File.readable?(file_name)

        # make sure it's a file
        raise "#{file_name} is a directory" if File.directory?(file_name)

        # if the user wants to change the name of the link
        link_name = options[:link] || file_name
        # sanatize the link name
        link_name = sanitize_filename(link_name.dup)

        # get full file path
        full_file_path = File.expand_path(file_name)

        # match any path that starts on an array and ends in a 'publish' directory
        raise "Please publish from the 'publish' directory" unless /^\/array\d\/publish\//.match(full_file_path)

        # get the file's path -- sans the file name
        file_path = options[:file_location] || full_file_path.gsub(file_name, '')

        # create a random directory
        if system "sudo -u webuser mkdir #{WEB_STORAGE_LOCATION}#{random_string}"
            # create link to file
            # puts "sudo -u webuser /bin/ln #{full_file_path} #{WEB_STORAGE_LOCATION}#{random_string}/#{link_name}"
            if system "sudo ln -T '#{full_file_path}' #{WEB_STORAGE_LOCATION}#{random_string}/#{link_name}"

                # print to the screen our link to the file
                puts out_msg = "Created link for #{file_name} at ftp://webuser:epscor@data.missouriepscor.org/fileshare/#{random_string}/#{link_name}"

                # if the user
                if options[:link_file]
                    File.open("#{file_path}published_links", "a+") { |io| io.puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} : #{out_msg}" }
                end

            else
                # remove the created folder if we can't add the link
                system "sudo -u webuser /bin/rm -rf #{WEB_STORAGE_LOCATION}#{random_string}"
                raise "Could not create FTP link"
            end
        else
            raise "Could not create FTP directory"
        end
    end
rescue Exception => e
    puts e.message
    abort
end