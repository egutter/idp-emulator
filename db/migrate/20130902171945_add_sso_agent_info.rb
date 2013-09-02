class AddSsoAgentInfo < ActiveRecord::Migration
  def self.up
    add_column :account_credentials, :agent_name, :string
    add_column :account_credentials, :agent_phone, :string
    add_column :account_credentials, :agent_code, :string
  end

  def self.down
    remove_column :account_credentials, :agent_name
    remove_column :account_credentials, :agent_phone
    remove_column :account_credentials, :agent_code
  end
end
