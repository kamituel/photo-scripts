require 'rubygems'
require 'ruby-box'
require 'yaml'
require 'launchy'

BOX_API_OAUTH_TOKEN_VALID_PERIOD_SEC = 3600 

def refresh_token (client_id, client_secret, account)
  session = RubyBox::Session.new({
    :client_id => client_id,
    :client_secret => client_secret,
    :access_token => account['token']
  })

  @token = session.refresh_token(account['refresh_token'])
  account['token'] = @token.token
  account['refresh_token'] = @token.refresh_token
end

def read_settings(filepath)
  settings = YAML::load_file(filepath)

  if settings['accounts'] == nil
    settings['accounts'] = {} 
  end

  now = Time.now.getutc.to_i
  settings['accounts'].each { |account_name, account|
    if now - account['timestamp'] > BOX_API_OAUTH_TOKEN_VALID_PERIOD_SEC 
      puts "Refreshing token for #{account_name}. Previous: #{account['token']}"
      refresh_token(settings['client_id'], settings['client_secret'], account)
      puts "Refreshing token for #{account_name}. New: #{account['token']}"
      account['timestamp'] = now
    end
  }

  return settings
end

def save_settings(filepath, settings)
  File.open( filepath, 'w' ) do |out|
    YAML.dump( settings, out )
  end
end

def usage()
  puts "Usage:"
  puts " ./script ..."
end

SETTINGS_PATH = File.join(File.dirname(File.expand_path(__FILE__)), "box-cp.settings.yml")
settings = read_settings(SETTINGS_PATH)
save_settings(SETTINGS_PATH, settings)
client_id = settings['client_id']
client_secret = settings['client_secret']

def get_account (settings, account_name)
  return settings['accounts'][account_name]
end

def add_account (client_id, client_secret)
  account = {}
  
  session = RubyBox::Session.new({
    :client_id => client_id,
    :client_secret => client_secret
  })

  authorize_url = session.authorize_url('http://127.0.0.1/box')
  Launchy.open authorize_url

  puts "\nTeraz wklej parametr 'code' z URL: "
  account['code'] = STDIN.gets.chomp

  @token = session.get_access_token(account['code'])
  account['token'] = @token.token
  account['refresh_token'] = @token.refresh_token
  account['timestamp'] = Time.now.getutc.to_i

  return account 
end

def box (client_id, client_secret, account)
   session = RubyBox::Session.new({
    :client_id => client_id,
    :client_secret => client_secret,
    :access_token => account['token']
  })

  return RubyBox::Client.new(session)
end

def box_mkdir (client, parent_dir, dir)
  client.folder(parent_dir).create_subfolder(dir)
end

def box_push (client, parent_dir, local_path)
  client.upload_file(local_path, parent_dir.dup)
end

# Return nil if remote_dir does not exist
def box_ls (client, remote_dir)
  return client.folder(remote_dir)
end

##### MAIN ######


# Commands:
#  account_name push local_path remote_path
#  account_name mkdir parent_dir dir_name
#  account_name ls remote_dir
#  account_name add

account_name = ARGV.shift
account = get_account(settings, account_name)

command = ARGV.shift

case command
  when "ls"
    remote_dir = ARGV.shift

    listing = box_ls(box(client_id, client_secret, account), remote_dir)
    if listing == nil
      exit -404
    end

    count = 0
    listing.items.each { |item| 
      puts "#{item.type} #{item.name}"
      count += 1
    }

    exit count
  when "mkdir"
    parent_dir = ARGV.shift
    dir = ARGV.shift

    if account.nil? 
      puts "Account #{account_name} does not exist"
      exit(13)
    end
    
    begin 
      box_mkdir(box(client_id, client_secret, account), parent_dir, dir) 
    rescue RubyBox::ItemNameInUse
      puts "Directory #{parent_dir}/#{dir} already exists on account #{account_name}"
      exit(21)
    end
  when "push"
    local_path = ARGV.shift
    remote_dir = ARGV.shift

    if account.nil? 
      puts "Account #{account_name} does not exist"
      exit(13)
    end

    unless File.file?(local_path)
      puts "Local file #{local_path} does not exist"
      exit(14)
    end

    begin
      box_push(box(client_id, client_secret, account), remote_dir, local_path)
    rescue RubyBox::AuthError
      puts "AuthError: probably token too old. Attempting to refresh"
      refresh_token(client_id, client_secret, account)
      puts "Trying to push #{local_path} again"
      box_push(box(client_id, client_secret, account), remote_dir, local_path)
    end
  when "add-account"
    settings['accounts'][account_name] = add_account(client_id, client_secret)
  else
    usage()
    exit(12)
end

save_settings(SETTINGS_PATH, settings)

exit 0

