#!/usr/bin/env ruby2.0
# gem install picasa
#require "rubygems"

require 'uri'
require 'net/http'

def get_album(albums, album_title)
	album = albums.find { |album| album.title == album_title }
end

def create_album (picasa, album_name)
	year, month, day = album_name.match(/(\d+)(?:\.(\d+))?(?:\.(\d+))? -.*/).captures
	picasa.album.create(
		:title => album_name,
		:summary => "",
		:access => "protected",
		:timestamp => (year ? Time.new(year, month, day) : Time.now).to_i * 1000
	)
end

begin 

user_id = "kamituel@gmail.com"
password = "aztjphhnyjhdtvup"

uri = URI.parse("https://picasaweb.google.com/data/feed/api/user/kamituel@gmail.com")
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Post.new(uri.path)
p "path #{uri.path}"
response = http.request(request)
p "yyy #{response}"

#albums.each{|album| 
#	#p "#{album.title} haha"
#	match = album.title.match(/(\d+)(?:\.(\d+))?(?:\.(\d+))? -.*/)
#	if match
#		year, month, day = match.captures
#		picasa.album.update(album, {:timestamp => (year ? Time.new(year, month, day) : Time.now).to_i * 1000})
#	else
#		#p "Nie pasuje"
#	end
#}

end
