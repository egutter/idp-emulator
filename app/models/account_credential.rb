class AccountCredential < ActiveRecord::Base

  validates :employee_id, :employer_id, :presence => true

  def self.instance
    AccountCredential.first || AccountCredential.new(:employee_id => 'TestEE', :employer_id => 'CH-DEV')
  end
end
