#!/usr/bin/env ruby2.0
require 'rubygems'
require 'launchy'
require 'yaml'
require 'net/http'
require 'openssl'
require 'json'

def usage () 
	puts "Usage:"
	puts "    oauth.rb add-app CLIENT_ID CLIENT_SECRET"
	puts "    oauth.rb add NAME"
	puts "    oauth.rb get NAME [client_id|client_secret|access_token]"
	puts "    oauth.rb refresh_token NAME"
	exit -1
end

client_id = "5sf8m1j7tz46hezbe6tr3g59w1u87di1"
client_secret = "l0KI0nz6v072ZRNPHzR8QKKMNLbLxfa8"

config_path = "#{Dir.home}/km.ruby.config"
if not File.exists?(config_path)
	File.open(config_path, 'w') do |out|
		YAML.dump( {}, out )
	end
end
config = YAML::load(File.read(config_path))

case ARGV.shift 
	when "add"
		name = ARGV.shift

		if not name
			usage()
		end

		url = "https://www.box.com/api/oauth2/authorize?response_type=code&client_id=#{config['client_id']}"
		Launchy.open url

		puts "In the browser, authorize app and then copy code=... from the address bar (URL) "
		code = STDIN.gets.chomp

		config['accounts'] = (config['accounts'] or {})
		config['accounts'][name] = {}

		url = URI.parse("https://www.box.com/api/oauth2/token")
		http = Net::HTTP.new(url.host, url.port)
		http.use_ssl = url.scheme == "https" ? true : false
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE

		req = Net::HTTP::Post.new(url.path)
		req.body = "grant_type=authorization_code&code=#{code}&client_id=#{config['client_id']}&client_secret=#{config['client_secret']}"

		res = JSON.parse(http.request(req).body())
		
		config['accounts'][name]['access_token'] = res['access_token']
		config['accounts'][name]['refresh_token'] = res['refresh_token']

	when "get"
		name = ARGV.shift
		param = ARGV.shift

		unless name
			usage()
		end

		unless config['accounts'][name]
			exit -10
		end

		case param
		when "client_id"
			puts config['client_id']
		when "client_secret"
			puts config['client_secret']
		when "access_token"
			puts config['accounts'][name]['access_token']
		else
			usage()
		end

	when "refresh-token"
		name = ARGV.shift

		if not name or not config['accounts'][name]
			usage()
		end

		url = URI.parse("https://www.box.com/api/oauth2/token")
		http = Net::HTTP.new(url.host, url.port)
		http.use_ssl = url.scheme == "https" ? true : false
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE

		req = Net::HTTP::Post.new(url.path)
		req.body = "grant_type=refresh_token&refresh_token=#{config['accounts'][name]['refresh_token']}&client_id=#{config['client_id']}&client_secret=#{config['client_secret']}"

		res = JSON.parse(http.request(req).body())
		
		config['accounts'][name]['access_token'] = res['access_token']
		config['accounts'][name]['refresh_token'] = res['refresh_token']

	else
		client_id = ARGV.shift
		client_secret = ARGV.shift

		if not client_id or not client_secret
			usage()
		end

		config["client_id"] = client_id
		config["client_secret"] = client_secret
end
		
File.open( config_path, 'w' ) do |out|
	YAML.dump( config, out )
end