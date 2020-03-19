#!/usr/bin/env ruby
require 'flickraw'
require 'yaml'
require 'optparse'
require 'mini_exiftool'

FlickRaw.api_key="b32ada91d04a3a8f846875c0d29f9f5a"
FlickRaw.shared_secret="3e76aa1b363a984f"

$config_path = "#{Dir.home}/km.flickr.config"

def authenticate
  if not File.exists?($config_path)
    File.open($config_path, 'w') do |out|
      YAML.dump( {}, out )
    end
  end
  config = YAML::load(File.read($config_path))

  if config['oauth_token'] and config['oauth_token_secret']
    flickr.access_token = config['oauth_token']
    flickr.access_secret = config['oauth_token_secret']
  else
    token = flickr.get_request_token
    auth_url = flickr.get_authorize_url(token['oauth_token'], :perms => 'write')

    puts
    puts
    puts "Open this url in your process to complete the authication process : #{auth_url}"
    puts "Copy here the number given when you complete the process."
    verify = gets.strip

    begin
      flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], verify)
      config['oauth_token'] = flickr.access_token
      config['oauth_token_secret'] = flickr.access_secret
    rescue FlickRaw::FailedResponse => e
      puts "Authentication failed : #{e.msg}"
    end
  end

  File.open( $config_path, 'w' ) do |out|
    YAML.dump( config, out )
  end
end

def revokeAuthTokens
  File.delete($config_path)
end

def set_get(name)
  photosets = flickr.photosets.getList
  return photosets.detect { |photoset| photoset['title'] == name }
end

def set_get_list
  per_page = 400
  page = 1
  remote_sets = []
  loop do
    response = flickr.photosets.getList(:per_page => per_page, :page => page)
    remote_sets.concat(Array(response))
    break if response.length < per_page
    page += 1
  end
  remote_sets
end

def set_order_alphabetically
  sets_valid_order = set_get_list.sort_by { |set| set['title'] }.reverse.map { |set| set['id'] }
  flickr.photosets.orderSets(:photoset_ids => sets_valid_order.join(','))
end

def set_create(name, cover_id)
  flickr.photosets.create(:title => name, :primary_photo_id => cover_id)
end

# I think it might be improved using .pages and .page:
# https://github.com/hanklords/flickraw/blob/efba05c8dd2b54fd6dd78e8b43f89d7212b46a12/test/test.rb#L308
def user_list_photos(album_name)
  per_page = 400
  page = 1
  remote_photos = []
  loop do
    response = flickr.photos.search(:user_id => 'me', :text => str_sanitize(album_name), :per_page => per_page, :page => page)
    remote_photos.concat(Array(response))
    break if response.length < per_page
    page += 1
  end
  remote_photos
end

def set_edit_photos(set, cover_id, photo_ids)
  return flickr.photosets.editPhotos(:photoset_id => set['id'], :primary_photo_id => cover_id, :photo_ids => photo_ids)
end

def upload_photo(filepath, album_name)
  filename = File.basename(filepath)
  flickr.upload_photo(filepath, :title => File.basename(filepath), :description => str_sanitize(album_name), :is_public => 0, :is_family => 0, :is_friend => 0, :content_type => 1)
end

def photo_exists_in_set?(photos, name)
  photos.detect { |photo| photo['title'] == name }
end

def get_content_type (filename)
  case File.extname(filename).downcase
    when ".jpg"
      return "image/jpeg"
  end
end

def str_sanitize(str)
  str.delete("^[a-zA-Z0-9]")
end

# For input such as: /some/directory/name, album name will be "name",
# for input such as: /some/directory/name/out, album name will be "name".
# So, in C1 session, set output folder name to "out".
def get_album_name(dir)
  path_parts = dir.split(File::SEPARATOR)

  if path_parts[-1] == "out"
    path_parts[-2]
  else
    path_parts[-1]
  end
end

def upload_dir_as_set(dir)
  if not dir.end_with?('/')
    dir = dir + "/"
  end

  album_name = get_album_name(dir)

  begin
    authenticate
    remote_photos = user_list_photos(album_name)
    p "Remote photos: #{remote_photos.length}"

    uploaded = []

    Dir.foreach(dir) do |item|
      next if item == '.' or item == '..'
      next if item.start_with?('.')
      next if item == '_raw'

      print "#{album_name}/#{item} "
      STDOUT.flush

      # Currently, upload photos only
      if not get_content_type(item)
        print "Not supported\n"
        STDOUT.flush
        next
      end

      # Do not upload photo that is already there
      # in a remote location.
      if photo_exists_in_set?(remote_photos, item)
        print "Exists remotely, won't upload\n"
        STDOUT.flush
        next
      end

      remote_photo_id = upload_photo(dir + item, album_name)
      print "Uploaded\n"
      STDOUT.flush

      uploaded << { 'id' => remote_photo_id, 'title' => item }
    end

    # Create list of all photos. It's a sum of list of all photos
    # in a remote directory present at time before this script started
    # and all photos uploaded by this script.
    all_photos = Array(remote_photos) + uploaded
    all_photos.sort_by! { |item| item['title'] }
    all_photos.map! { |item| item['id'] }

    # Do not create set when there is no photos there.
    if all_photos.length < 1
      return
    end

    set = set_get(album_name)

    # If there is no set under album_name, create it.
    if set.nil?
      p "Set #{album_name} does not exist. Creating..."
      set = set_create(album_name, all_photos[0])
    end

    # Now, upload all photos to remote set.
    set_edit_photos(set, all_photos[0], all_photos.join(","))

    p "Done."
  rescue FlickRaw::OAuthClient::FailedResponse, FlickRaw::FailedResponse => e
    p "\n\nFlickr library error: #{e}\n"
    revokeAuthTokens
    upload_dir_as_set(dir)
  end
end

def split_i18n_str(s)
  if not s
    return {:pl => "", :en => ""}
  end

  pl, en = s.match(/PL:(.*)EN:(.*)/).captures

  if pl and en
    pl.strip!
    en.strip!
    return {:pl => pl, :en => en}
  else
    return {:pl => s.strip, :en => s.strip}
  end
end

# ====

opts = {}
OptionParser.new do |opt|
  opt.on('-p', '--photo FILE_PATH') { |o| opts[:photo] = o }
  opt.on('-a', '--album DIR_PATH') { |o| opts[:album] = o }
  opt.on('--fix-album-order') { |o| opts[:fix_album_order] = o }
end.parse!

puts opts

if opts[:album] and opts[:photo]
  p 'Cannot upload both an album and a photo at the same time.'
  exit 1
end

if opts[:album]
  authenticate

  dir = opts[:album]
  if not File.directory?(dir)
    p "#{dir} is not a directory"
    exit -1
  end

  upload_dir_as_set(dir)
end

if opts[:photo]
  authenticate

  photo_file = opts[:photo]
  phot_meta = MiniExiftool.new(photo_file)
  puts phot_meta.f_number
  puts phot_meta.focal_length_in_35mm_film
  puts phot_meta.exposure_time
  puts phot_meta.artist
  puts phot_meta.maker_note
  puts phot_meta.model
  puts phot_meta.user_comment
  puts phot_meta.comment
  puts phot_meta.creator
  puts phot_meta.headline
  puts phot_meta.description
  puts phot_meta.category



  title = split_i18n_str(phot_meta.headline)
  desc = split_i18n_str(phot_meta.description)

  puts title
  puts desc

  standard_groups = ["alpha-nex", "captureone", "2335287@N24", "sony-a7", "ilce-7", "sony_alpha_dslr-a200"]
  emount_lens_groups = ["nex-lenses"]
  batis85 = ["2803969@N25"]


  # flickr.groups.pools.add(:photo_id => "30166719022", :group_id => "2803969@N25")

  exit
  flickr.upload_photo(filepath,
                      :title => title[:en],
                      :description => desc[:en],
                      :is_public => 1,
                      :content_type => 1,
                      :tags => "")


end

if opts[:fix_album_order]
  authenticate
  set_order_alphabetically
end
