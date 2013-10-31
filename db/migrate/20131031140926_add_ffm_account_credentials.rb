class AddFfmAccountCredentials < ActiveRecord::Migration
  def self.up
    add_column :account_credentials, :ffm_lastname, :string
    add_column :account_credentials, :ffm_firstname, :string
    add_column :account_credentials, :ffm_consumerid, :string
    add_column :account_credentials, :ffm_partner_consumerid, :string
    add_column :account_credentials, :ffm_partner_token, :string
    add_column :account_credentials, :ffm_usertype, :string
  end

  def self.down
    remove_column :account_credentials, :ffm_lastname
    remove_column :account_credentials, :ffm_firstname
    remove_column :account_credentials, :ffm_consumerid
    remove_column :account_credentials, :ffm_partner_consumerid
    remove_column :account_credentials, :ffm_partner_token
    remove_column :account_credentials, :ffm_usertype
  end
end