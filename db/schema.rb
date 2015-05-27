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

ActiveRecord::Schema.define(version: 20150526232821) do

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
    t.integer  "authorization_setup_id"
  end

  add_index "authorizations", ["authorization_setup_id"], name: "index_authorizations_on_authorization_setup_id"

  create_table "captures", force: :cascade do |t|
    t.float    "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "admin_id"
  end

  add_index "captures", ["admin_id"], name: "index_captures_on_admin_id"

  create_table "checkout_authorizations", id: false, force: :cascade do |t|
    t.integer  "checkout_id"
    t.integer  "authorization_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "checkout_authorizations", ["authorization_id"], name: "index_checkout_authorizations_on_authorization_id"
  add_index "checkout_authorizations", ["checkout_id"], name: "index_checkout_authorizations_on_checkout_id"

  create_table "checkouts", force: :cascade do |t|
    t.string   "token"
    t.float    "amount"
    t.string   "client_ip"
    t.text     "response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "checkouts", ["token"], name: "index_checkouts_on_token"

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

  create_table "purchases", force: :cascade do |t|
    t.float    "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tote_item_checkouts", id: false, force: :cascade do |t|
    t.integer  "tote_item_id"
    t.integer  "checkout_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "tote_item_checkouts", ["checkout_id"], name: "index_tote_item_checkouts_on_checkout_id"
  add_index "tote_item_checkouts", ["tote_item_id"], name: "index_tote_item_checkouts_on_tote_item_id"

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
