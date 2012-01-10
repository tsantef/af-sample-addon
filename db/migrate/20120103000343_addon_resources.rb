class AddonResources < ActiveRecord::Migration
  def self.up
    create_table :addon_resources do |t|
      t.string :addon_name
      t.string :customer_id
      t.string :callback_url
      t.string :plan
      t.text :options
      t.integer :callback_count, :default => 0
      
      t.string :status
      
      t.timestamps
    end
    add_index :addon_resources, :customer_id
  end

  def self.down
    drop_table :addon_resources
  end
end
