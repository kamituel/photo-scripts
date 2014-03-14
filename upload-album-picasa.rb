#!/usr/bin/env ruby2.0
# gem install picasa
require "rubygems"
require "Picasa"

def get_album(albums, album_title)
	album = albums.find { |album| album.title == album_title }
end

def get_photo(photos, photo_title)
	return photos.find { |photo| photo.title == photo_title }
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

def get_content_type (filename)
	case File.extname(filename).downcase
	when ".jpg"
		return "image/jpeg"
	end
end

begin 

dir = ARGV.shift
if not dir or not File.directory?(dir)
	p "#{dir} is not a directory"
	exit -1
end

album_name = File.basename(dir)

picasa = Picasa::Client.new(:user_id => "kamituel@gmail.com", :password => "aztjphhnyjhdtvup")
albums = picasa.album.list.entries
remote_album = get_album(albums, album_name)

if not remote_album
	p "Album #{album_name} does not exists on picasa, creating"
	create_album(picasa, album_name)
	albums = picasa.album.list.entries
	remote_album = get_album(albums, album_name)
end

if not remote_album
	p "Could not create album named #{album_name}"
	exit -2
end

photos = picasa.album.show(remote_album.id).entries

Dir.foreach(dir) do |item|
	next if item == '.' or item == '..'
	next if item == '_raw'

	next if get_photo(photos, item)

	photo = File.binread("#{dir}/#{item}")

	ctype = get_content_type(item)
	if not ctype
		p "File #{item} not supported, skipped"
		next
	end

	picasa.photo.create(remote_album.id, {
		:binary => photo,
		:title => item,
		:content_type => ctype
	})
end


end
