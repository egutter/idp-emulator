class AccountCredential < ActiveRecord::Base
  def self.instance
    AccountCredential.first || AccountCredential.new(:employee_id => 'TestEE', :employer_id => 'CH-DEV')
  end
end
