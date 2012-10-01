class CreateAccountCredentials < ActiveRecord::Migration
  def self.up
    create_table :account_credentials do |t|
      t.string :employee_id
      t.string :employer_id

      t.timestamps
    end
  end

  def self.down
    drop_table :account_credentials
  end
end
