require 'rubygems'
require 'mongo'
require 'sinatra'
require 'sinatra/activerecord'
require 'json'
require 'db/models'
require 'rest-client'
Dir["lib/*.rb"].each {|file| require file }

use Rack::MethodOverride
ActiveRecord::Base.establish_connection(YAML::load(File.open('config/database.yml'))["development"])

set :public_folder, File.dirname(__FILE__) + '/static'

$addon_names = ['provider','heroku']
$addon_config = nil

# SSO 
get '/:addon_name/resources/:resource_id' do
      puts red "1"
  if load_config
        puts red "ZZZ"
    timestamp = Time.now.to_i
    sso_salt = $addon_config['sso_salt']
    id = $addon_config['id']
        puts red "ZZZ"
    authstring = id.to_s + ':' + sso_salt + ':' + params['timestamp'].to_s
        puts red "ZZZ"
    token = Digest::SHA1.hexdigest(authstring)
    puts red "ZZZ"
    if token == params['token']
      res = AddonResources.find_by_id(params['resource_id'])
      puts red "ZZZ"
      puts red id if res.nil?
      throw(:halt, [404,  "Not Found\n"]) if res.nil?
      return "SSO URL for #{id}"
    end
  end
  throw(:halt, [404, "Not found\n"])
end

# Provision
post '/:addon_name/resources' do 
  protected!
  
  # validate request
  addon_name = get_app_name
  
  puts "Provision attempt by " + bright(addon_name.capitalize)
  
  payload = JSON.parse(request.body.read)
  
  customer_key = $addon_config['customer_key']
  
  if payload[customer_key].nil? 
    puts "Client failed to provide customer_id"
    throw(:halt, [400, "Bad Request: Missing customer_id\n"])
  end
  
  if payload['plan'].nil?
    puts "Client failed to provide plan"
    throw(:halt, [400, "Bad Request: Missing plan\n"])
  end
  
  if payload['callback_url'].nil?
    puts "Client failed to provide resource_url"
    throw(:halt, [400, "Bad Request: Missing resource_url\n"])
  end
  
  if payload['options'].nil?
    puts "Client failed to provide options"
    throw(:halt, [400, "Bad Request: Missing options\n"])
  end

  # record provisioned resource
  res = AddonResources.new(
    :addon_name => addon_name,
    :customer_id => payload[customer_key], 
    :callback_url => payload['callback_url'], 
    :plan => payload['plan'], 
    :options => payload['options'],
    :status => 'new'
  )

  res.save!
  
  api_response = BSON::OrderedHash.new
  api_response[:id] = res.id
  api_response[:config] = $addon_config['config']
  api_response[:message] = "success"
  
  # do async 
  child = fork do
    sleep(8)
    payload = BSON::OrderedHash.new
    payload[:id] = res.id
    payload[:config] = $addon_config['config']
    puts "Calling Back: " + bright("[ ") + bgreen(res.callback_url) + bright(" ]") 
    response = RestClient.put res.callback_url, JSON.generate(payload), {:content_type => 'application/json', :accept => 'application/json'}
  end
  
  content_type :json
  api_response.to_json(:include => [:id, :message])
    
end

# Update resource
put '/:addon_name/resources/:resource_id' do
  protected!
  
  res = AddonResources.find_by_id(params['resource_id'])
  if res.nil?
    throw(:halt, [404,  "Not Found\n"])
  else
    payload = JSON.parse(request.body.read)
    customer_key = $addon_config['customer_key']
    
    if !payload[customer_key].nil? 
      res.customer_id = payload[customer_key]
    end

    if !payload['plan'].nil?
      res.plan = payload['plan']
    end

    if !payload['callback_url'].nil?
      res.callback_url = payload['callback_url']
    end

    if !payload['options'].nil?
      res.options = payload['options']
    end
    
    res.save!
  end
end

# Deprovision
delete '/:addon_name/resources/:resource_id' do
  protected!
  
  res = AddonResources.find_by_id(params['resource_id'])
  if res.nil?
    throw(:halt, [404,  "Not Found\n"])
  else
    res.delete
  end
end
