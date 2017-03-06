#!/usr/bin/env ruby
require 'httparty'
require 'nokogiri'
require 'securerandom'
require 'curb'

def load_users(file = '/var/www/exports/xml/users.xml')

	# setup static vars
	user_url = 'https://data.missouriepscor.org/api/3/action/user_list'
	create_url = 'https://data.missouriepscor.org/api/3/action/user_create'
	
	# if we can get the file
	if FileTest.exists?(file)
		# create a get request to grab all the CKAN users
		ckan_req = HTTParty.get(user_url)
		# if that call was successful
		if ckan_req.success?
			# get the list of ckan user names
			ckan_users = ckan_req["result"].map{ |usr| usr["name"] }
			# open our drupal file
			xml_file = File.open(file)
			# parse it
			doc = Nokogiri::XML(xml_file)
			# close it
			xml_file.close
			# for each drupal user...
			doc.xpath("//user").each do |usr|
				# create ckan friendly hash 
				usr_hash = {}
				usr_hash[:name] = usr.css('username').text.downcase.sub(" ", "_").sub(/[^\w-]+/, "")
				usr_hash[:email] = usr.css('mail').text
				usr_hash[:fullname] = "#{usr.css('firstname').text} #{usr.css('lastname').text}"
				usr_hash[:password] = SecureRandom.hex
				# send the request to CKAN to create the user
				# unless the user already exists
				unless ckan_users.include? usr_hash[:name]

					# File.open("/home/letourneaujj/out.txt", 'a+') {|f| f.write(usr_hash.to_s) }

					ckan_response = Curl.post(create_url, usr_hash.to_json) do |curl|
						curl.headers['Accept'] = 'application/json'
						curl.headers['Content-Type'] = 'application/json'
						curl.headers['Authorization'] = 'f265f0a7-1268-43d0-a265-41e57ce24370'
						curl.verbose=true
						curl.on_failure do |response, err|
							STDERR.puts "Could not load #{usr_hash[:name]}: #{response.response_code} #{err.inspect}"
						end
					end
					
				end 
			end 
		else
			STDERR.puts "Could not get url: '#{user_url}'"
		end
	else
		STDERR.puts "Could not open file"
	end
end