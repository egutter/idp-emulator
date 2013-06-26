class AddEvoOneFieldsToAccountEnrollmentCredential < ActiveRecord::Migration
  def self.up
    add_column :account_credentials, :plan_year_name, :string
    add_column :account_credentials, :plan_year_start, :string
  end

  def self.down
    remove_column :account_credentials, :plan_year_name
    remove_column :account_credentials, :plan_year_start
  end
end
