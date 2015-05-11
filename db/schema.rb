# encoding: UTF-8
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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150508224936) do

  create_table "authorization_setup_tote_items", force: :cascade do |t|
    t.integer  "authorization_setup_id"
    t.integer  "tote_item_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "authorization_setup_tote_items", ["authorization_setup_id"], name: "index_authorization_setup_tote_items_on_authorization_setup_id"
  add_index "authorization_setup_tote_items", ["tote_item_id"], name: "index_authorization_setup_tote_items_on_tote_item_id"

  create_table "authorization_setups", force: :cascade do |t|
    t.string   "token"
    t.float    "amount"
    t.string   "client_ip"
    t.text     "response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "authorizations", force: :cascade do |t|
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "token"
    t.string   "payer_id"
    t.float    "amount"
    t.string   "correlation_id"
    t.string   "transaction_id"
    t.datetime "payment_date"
    t.float    "gross_amount"
    t.string   "gross_amount_currency_id"
    t.string   "payment_status"
    t.string   "pending_reason"
  end

  create_table "postings", force: :cascade do |t|
    t.text     "description"
    t.integer  "quantity_available"
    t.float    "price"
    t.integer  "user_id"
    t.integer  "product_id"
    t.integer  "unit_category_id"
    t.integer  "unit_kind_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "postings", ["product_id"], name: "index_postings_on_product_id"
  add_index "postings", ["unit_category_id"], name: "index_postings_on_unit_category_id"
  add_index "postings", ["unit_kind_id"], name: "index_postings_on_unit_kind_id"
  add_index "postings", ["user_id"], name: "index_postings_on_user_id"

  create_table "products", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tote_items", force: :cascade do |t|
    t.integer  "quantity"
    t.float    "price"
    t.integer  "status"
    t.integer  "posting_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "user_id"
  end

  add_index "tote_items", ["posting_id"], name: "index_tote_items_on_posting_id"
  add_index "tote_items", ["user_id"], name: "index_tote_items_on_user_id"

  create_table "unit_categories", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "unit_kinds", force: :cascade do |t|
    t.string   "name"
    t.integer  "unit_category_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "unit_kinds", ["unit_category_id"], name: "index_unit_kinds_on_unit_category_id"

# Could not dump table "users" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

end
