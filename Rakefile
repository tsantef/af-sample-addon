require 'sinatra'
require 'sinatra/activerecord/rake'

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Migration.verbose = true

ActiveRecord::Base.establish_connection(YAML::load(File.open('config/database.yml'))["development"])