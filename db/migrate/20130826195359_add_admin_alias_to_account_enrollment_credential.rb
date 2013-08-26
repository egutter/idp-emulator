class AddAdminAliasToAccountEnrollmentCredential < ActiveRecord::Migration
  def self.up
    add_column :account_credentials, :administrator_alias, :string
  end

  def self.down
    remove_column :account_credentials, :administrator_alias
  end
end
