# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130902171945) do

  create_table "account_credentials", :force => true do |t|
    t.string   "employee_id"
    t.string   "employer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name_id"
    t.string   "plan_year_name"
    t.string   "plan_year_start"
    t.string   "uuid"
    t.string   "administrator_alias"
    t.string   "agent_name"
    t.string   "agent_phone"
    t.string   "agent_code"
  end

  create_table "accounts", :force => true do |t|
    t.string   "name"
    t.integer  "account_credential_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
