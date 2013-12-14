class AddIssuerShoppingCartIdToAccountCredential < ActiveRecord::Migration
  def self.up
    add_column :account_credentials, :ffm_issuer_shopping_cart_id, :string
  end

  def self.down
    remove_column :account_credentials, :ffm_issuer_shopping_cart_id
  end
end
