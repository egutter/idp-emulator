class AddNameIdToAccountCredentials < ActiveRecord::Migration
  def self.up
    add_column :account_credentials, :name_id, :string
  end

  def self.down
    remove_column :account_credentials, :name_id
  end
end
