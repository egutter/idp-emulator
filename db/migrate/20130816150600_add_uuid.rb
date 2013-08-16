class AddUuid < ActiveRecord::Migration
  def self.up
    add_column :account_credentials, :uuid, :string
  end

  def self.down
    remove_column :account_credentials, :uuid
  end
end
