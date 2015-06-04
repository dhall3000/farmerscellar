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

ActiveRecord::Schema.define(version: 20150604193940) do

  create_table "account_states", force: :cascade do |t|
    t.integer  "state"
    t.text     "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "admin_bulk_buys", id: false, force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "bulk_buy_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "admin_bulk_buys", ["bulk_buy_id"], name: "index_admin_bulk_buys_on_bulk_buy_id"
  add_index "admin_bulk_buys", ["user_id"], name: "index_admin_bulk_buys_on_user_id"

  create_table "authorization_purchases", id: false, force: :cascade do |t|
    t.integer  "authorization_id"
    t.integer  "purchase_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "authorization_purchases", ["authorization_id"], name: "index_authorization_purchases_on_authorization_id"
  add_index "authorization_purchases", ["purchase_id"], name: "index_authorization_purchases_on_purchase_id"

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

  create_table "bulk_buy_purchase_receivables", id: false, force: :cascade do |t|
    t.integer  "purchase_receivable_id"
    t.integer  "bulk_buy_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "bulk_buy_purchase_receivables", ["bulk_buy_id"], name: "index_bulk_buy_purchase_receivables_on_bulk_buy_id"
  add_index "bulk_buy_purchase_receivables", ["purchase_receivable_id"], name: "index_bulk_buy_purchase_receivables_on_purchase_receivable_id"

  create_table "bulk_buy_tote_items", id: false, force: :cascade do |t|
    t.integer  "tote_item_id"
    t.integer  "bulk_buy_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "bulk_buy_tote_items", ["bulk_buy_id"], name: "index_bulk_buy_tote_items_on_bulk_buy_id"
  add_index "bulk_buy_tote_items", ["tote_item_id"], name: "index_bulk_buy_tote_items_on_tote_item_id"

  create_table "bulk_buys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float    "amount"
  end

  create_table "bulk_purchase_purchases", id: false, force: :cascade do |t|
    t.integer  "purchase_id"
    t.integer  "bulk_purchase_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "bulk_purchase_purchases", ["bulk_purchase_id"], name: "index_bulk_purchase_purchases_on_bulk_purchase_id"
  add_index "bulk_purchase_purchases", ["purchase_id"], name: "index_bulk_purchase_purchases_on_purchase_id"

  create_table "bulk_purchase_receivables", id: false, force: :cascade do |t|
    t.integer  "purchase_receivable_id"
    t.integer  "bulk_purchase_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "bulk_purchase_receivables", ["bulk_purchase_id"], name: "index_bulk_purchase_receivables_on_bulk_purchase_id"
  add_index "bulk_purchase_receivables", ["purchase_receivable_id"], name: "index_bulk_purchase_receivables_on_purchase_receivable_id"

  create_table "bulk_purchases", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

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

  create_table "payment_payable_tote_items", id: false, force: :cascade do |t|
    t.integer  "tote_item_id"
    t.integer  "payment_payable_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "payment_payable_tote_items", ["payment_payable_id"], name: "index_payment_payable_tote_items_on_payment_payable_id"
  add_index "payment_payable_tote_items", ["tote_item_id"], name: "index_payment_payable_tote_items_on_tote_item_id"

  create_table "payment_payables", force: :cascade do |t|
    t.float    "amount"
    t.float    "amount_paid"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
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
    t.date     "delivery_date"
  end

  add_index "postings", ["product_id"], name: "index_postings_on_product_id"
  add_index "postings", ["unit_category_id"], name: "index_postings_on_unit_category_id"
  add_index "postings", ["unit_kind_id"], name: "index_postings_on_unit_kind_id"
  add_index "postings", ["user_id"], name: "index_postings_on_user_id"

  create_table "producer_product_commissions", id: false, force: :cascade do |t|
    t.integer  "product_id"
    t.integer  "user_id"
    t.float    "commission"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "producer_product_commissions", ["product_id"], name: "index_producer_product_commissions_on_product_id"
  add_index "producer_product_commissions", ["user_id"], name: "index_producer_product_commissions_on_user_id"

  create_table "products", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "purchase_bulk_buys", id: false, force: :cascade do |t|
    t.integer  "purchase_id"
    t.integer  "bulk_buy_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "purchase_bulk_buys", ["bulk_buy_id"], name: "index_purchase_bulk_buys_on_bulk_buy_id"
  add_index "purchase_bulk_buys", ["purchase_id"], name: "index_purchase_bulk_buys_on_purchase_id"

  create_table "purchase_purchase_receivables", id: false, force: :cascade do |t|
    t.integer  "purchase_id"
    t.integer  "purchase_receivable_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "purchase_purchase_receivables", ["purchase_id"], name: "index_purchase_purchase_receivables_on_purchase_id"
  add_index "purchase_purchase_receivables", ["purchase_receivable_id"], name: "index_purchase_purchase_receivables_on_purchase_receivable_id"

  create_table "purchase_receivable_tote_items", id: false, force: :cascade do |t|
    t.integer  "tote_item_id"
    t.integer  "purchase_receivable_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "purchase_receivable_tote_items", ["purchase_receivable_id"], name: "index_purchase_receivable_tote_items_on_purchase_receivable_id"
  add_index "purchase_receivable_tote_items", ["tote_item_id"], name: "index_purchase_receivable_tote_items_on_tote_item_id"

  create_table "purchase_receivables", force: :cascade do |t|
    t.float    "amount"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.float    "amount_paid"
  end

  create_table "purchases", force: :cascade do |t|
    t.float    "amount"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "payer_id"
    t.string   "token"
    t.text     "response"
    t.float    "gross_amount"
    t.float    "fee_amount"
    t.float    "net_amount"
  end

  add_index "purchases", ["payer_id"], name: "index_purchases_on_payer_id"
  add_index "purchases", ["token"], name: "index_purchases_on_token"

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

  create_table "user_account_states", id: false, force: :cascade do |t|
    t.integer  "account_state_id"
    t.integer  "user_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "user_account_states", ["account_state_id"], name: "index_user_account_states_on_account_state_id"
  add_index "user_account_states", ["user_id"], name: "index_user_account_states_on_user_id"

  create_table "user_payment_payables", id: false, force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "payment_payable_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "user_payment_payables", ["payment_payable_id"], name: "index_user_payment_payables_on_payment_payable_id"
  add_index "user_payment_payables", ["user_id"], name: "index_user_payment_payables_on_user_id"

  create_table "user_purchase_receivables", id: false, force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "purchase_receivable_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "user_purchase_receivables", ["purchase_receivable_id"], name: "index_user_purchase_receivables_on_purchase_receivable_id"
  add_index "user_purchase_receivables", ["user_id"], name: "index_user_purchase_receivables_on_user_id"

# Could not dump table "users" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

end
