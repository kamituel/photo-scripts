#!/usr/bin/env ruby2.0
require 'rubygems'
require 'ruby-box'

SELF_DIR = File.expand_path(File.dirname(__FILE__))
OAUTH_MANAGER = "#{SELF_DIR}/oauth.rb"

def usage () 
	puts "Usage:"
	puts "   box.rb ACCOUNT_NAME push    local_file   remote_dir"
	puts "   box.rb ACCOUNT_NAME ls      remote_dir"
	puts "   box.rb ACCOUNT_NAME mkdir   remote_dir   new_dir"
	exit -1
end

account_name = ARGV.shift
command = ARGV.shift
unless account_name and command
	usage()
end

def main (account_name, command, argv)
	client_id = `#{OAUTH_MANAGER} get #{account_name} client_id`.chomp
	client_secret = `#{OAUTH_MANAGER} get #{account_name} client_secret`.chomp
	access_token = `#{OAUTH_MANAGER} get #{account_name} access_token`.chomp

	if (client_id.nil? or client_id.empty?) or (client_secret.nil? or client_secret.empty?) or (access_token.nil? or access_token.empty?)
		p "Invalid OAuth2 credentials"
		exit -10
	end

	session = RubyBox::Session.new({
		:client_id => client_id,
		:client_secret => client_secret,
		:access_token => access_token
	})
	client = RubyBox::Client.new(session)

	case command
	when "push"
		local_file = argv.shift
		remote_dir = argv.shift

		unless local_file and remote_dir
			usage();
		end

		unless File.file?(local_file)
			puts "Could not open file: #{local_file}"
			exit -2
		end

		client.upload_file(local_file, remote_dir.dup)
	when "pull"
		puts "not implemented yet"
		exit -3
	when "ls"
		remote_dir = argv.shift

		unless remote_dir
			usage()
		end

		folder = client.folder(remote_dir)
		unless folder.nil?
			folder.items.each { |item| 
				puts "#{item.type} #{item.name}"
			}
		end
	when "mkdir"
		remote_dir = argv.shift
		new_remote_dir = argv.shift

		unless remote_dir and new_remote_dir
			usage()
		end

		begin
			client.folder(remote_dir).create_subfolder(new_remote_dir)
		rescue RubyBox::ItemNameInUse
			puts "#{remote_dir}/#{new_remote_dir} already exists on #{account_name}"
			exit -5
		end
	else
		usage()
	end
end

begin
	main(account_name, command, ARGV.dup)
rescue RubyBox::AuthError
	`#{OAUTH_MANAGER} refresh-token #{account_name}`
	main(account_name, command, ARGV.dup)
end

