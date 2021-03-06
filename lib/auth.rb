def protected!
  unless authorized?
    response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
    throw(:halt, [401, "Not authorized\n"])
  end
end

def load_config
  config_path = "config/partners/#{params[:partner_name]}.json"

  if FileTest.exist?(config_path)
    config_file = File.open(config_path, 'r')
    config_json = config_file.readlines.to_s
    $addon_config = JSON.parse(config_json)
    $addon_config
  else
    false
  end
end

def authorized?
  if load_config

    @auth ||=  Rack::Auth::Basic::Request.new(request.env)

    if @auth.credentials.nil?
      puts "No credentials"
    else
      puts @auth.credentials.inspect
    end

    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [$addon_config['username'], $addon_config['password']]
  else
    puts "Request from unknown partner [ " + red(partner_name) + " ]"
    false
  end
  
end
