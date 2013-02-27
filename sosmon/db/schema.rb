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

ActiveRecord::Schema.define(:version => 20130227174947) do

  create_table "clients", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "services", :force => true do |t|
    t.string   "name",       :null => false
    t.string   "portfolio"
    t.string   "tags"
    t.integer  "client_id",  :null => false
    t.text     "desc"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "services", ["client_id"], :name => "index_services_on_client_id"

  create_table "tests", :force => true do |t|
    t.string   "name",                         :null => false
    t.integer  "service_id",                   :null => false
    t.string   "check_url",                    :null => false
    t.string   "uuid"
    t.boolean  "enabled",    :default => true
    t.string   "tags"
    t.string   "opmode"
    t.string   "status"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  add_index "tests", ["service_id"], :name => "index_tests_on_service_id"

end
