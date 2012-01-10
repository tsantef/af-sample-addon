class AddonResources < ActiveRecord::Base
  validates_presence_of :customer_id
  validates_presence_of :callback_url
  
end