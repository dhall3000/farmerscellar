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

ActiveRecord::Schema.define(version: 20160725204236) do

  create_table "access_codes", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text     "notes"
  end

  add_index "access_codes", ["user_id"], name: "index_access_codes_on_user_id"

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
    t.float    "amount_purchased"
    t.text     "response"
    t.string   "ack"
  end

  create_table "bp_pp_mp_commons", id: false, force: :cascade do |t|
    t.integer  "bulk_payment_id"
    t.integer  "pp_mp_common_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "bp_pp_mp_commons", ["bulk_payment_id"], name: "index_bp_pp_mp_commons_on_bulk_payment_id"
  add_index "bp_pp_mp_commons", ["pp_mp_common_id"], name: "index_bp_pp_mp_commons_on_pp_mp_common_id"

  create_table "bp_pp_mp_errors", id: false, force: :cascade do |t|
    t.integer  "bulk_payment_id"
    t.integer  "pp_mp_error_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "bp_pp_mp_errors", ["bulk_payment_id"], name: "index_bp_pp_mp_errors_on_bulk_payment_id"
  add_index "bp_pp_mp_errors", ["pp_mp_error_id"], name: "index_bp_pp_mp_errors_on_pp_mp_error_id"

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

  create_table "bulk_payment_payables", force: :cascade do |t|
    t.integer  "payment_payable_id"
    t.integer  "bulk_payment_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "bulk_payment_payables", ["bulk_payment_id"], name: "index_bulk_payment_payables_on_bulk_payment_id"
  add_index "bulk_payment_payables", ["payment_payable_id"], name: "index_bulk_payment_payables_on_payment_payable_id"

  create_table "bulk_payments", force: :cascade do |t|
    t.integer  "num_payees"
    t.float    "total_payments_amount"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "bulk_purchase_receivables", id: false, force: :cascade do |t|
    t.integer  "purchase_receivable_id"
    t.integer  "bulk_purchase_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "bulk_purchase_receivables", ["bulk_purchase_id"], name: "index_bulk_purchase_receivables_on_bulk_purchase_id"
  add_index "bulk_purchase_receivables", ["purchase_receivable_id"], name: "index_bulk_purchase_receivables_on_purchase_receivable_id"

  create_table "bulk_purchases", force: :cascade do |t|
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
    t.float    "gross"
    t.float    "payment_processor_fee_withheld_from_us"
    t.float    "commission"
    t.float    "net"
    t.float    "payment_processor_fee_withheld_from_producer", default: 0.0
  end

  create_table "business_interfaces", force: :cascade do |t|
    t.string   "name",                 null: false
    t.boolean  "order_email_accepted"
    t.string   "order_email"
    t.string   "order_instructions"
    t.boolean  "paypal_accepted"
    t.string   "paypal_email"
    t.string   "payment_instructions"
    t.integer  "user_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "business_interfaces", ["user_id"], name: "index_business_interfaces_on_user_id"

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
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.boolean  "is_rt",      default: false
  end

  add_index "checkouts", ["is_rt"], name: "index_checkouts_on_is_rt"
  add_index "checkouts", ["token"], name: "index_checkouts_on_token"

  create_table "deliveries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delivery_dropsites", id: false, force: :cascade do |t|
    t.integer  "delivery_id"
    t.integer  "dropsite_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "delivery_dropsites", ["delivery_id"], name: "index_delivery_dropsites_on_delivery_id"
  add_index "delivery_dropsites", ["dropsite_id"], name: "index_delivery_dropsites_on_dropsite_id"

  create_table "delivery_postings", id: false, force: :cascade do |t|
    t.integer  "posting_id"
    t.integer  "delivery_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "delivery_postings", ["delivery_id"], name: "index_delivery_postings_on_delivery_id"
  add_index "delivery_postings", ["posting_id"], name: "index_delivery_postings_on_posting_id"

  create_table "dropsites", force: :cascade do |t|
    t.string   "name"
    t.string   "phone"
    t.string   "hours"
    t.string   "address"
    t.text     "access_instructions"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.boolean  "active"
    t.string   "city"
    t.string   "state"
    t.integer  "zip"
  end

  create_table "food_categories", force: :cascade do |t|
    t.string   "name",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "parent_id"
  end

  add_index "food_categories", ["parent_id"], name: "index_food_categories_on_parent_id"

  create_table "nightly_task_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payment_payable_payments", force: :cascade do |t|
    t.integer  "payment_payable_id"
    t.integer  "payment_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "payment_payable_payments", ["payment_id"], name: "index_payment_payable_payments_on_payment_id"
  add_index "payment_payable_payments", ["payment_payable_id"], name: "index_payment_payable_payments_on_payment_payable_id"

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

  create_table "payments", force: :cascade do |t|
    t.float    "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pickup_codes", force: :cascade do |t|
    t.string   "code",       null: false
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "pickup_codes", ["code"], name: "index_pickup_codes_on_code"
  add_index "pickup_codes", ["user_id"], name: "index_pickup_codes_on_user_id"

  create_table "pickups", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "pickups", ["user_id"], name: "index_pickups_on_user_id"

  create_table "posting_recurrences", force: :cascade do |t|
    t.integer  "frequency",      default: 0,     null: false
    t.boolean  "on",             default: false, null: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.datetime "reference_date",                 null: false
  end

  create_table "postings", force: :cascade do |t|
    t.string   "description",                                   null: false
    t.integer  "quantity_available",            default: 0
    t.float    "price",                         default: 0.0
    t.integer  "user_id",                                       null: false
    t.integer  "product_id",                                    null: false
    t.integer  "unit_id",                                       null: false
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.boolean  "live",                          default: false
    t.datetime "delivery_date",                                 null: false
    t.datetime "commitment_zone_start",                         null: false
    t.integer  "posting_recurrence_id"
    t.integer  "state",                         default: 0,     null: false
    t.boolean  "late_adds_allowed",             default: false
    t.string   "product_attributes"
    t.string   "price_equivalency_description"
    t.string   "unit_equivalency_description"
    t.string   "product_identifier"
    t.integer  "units_per_case",                default: 1
    t.string   "product_id_code"
  end

  add_index "postings", ["posting_recurrence_id"], name: "index_postings_on_posting_recurrence_id"
  add_index "postings", ["product_id"], name: "index_postings_on_product_id"
  add_index "postings", ["state"], name: "index_postings_on_state"
  add_index "postings", ["unit_id"], name: "index_postings_on_unit_id"
  add_index "postings", ["user_id"], name: "index_postings_on_user_id"

  create_table "pp_mp_commons", force: :cascade do |t|
    t.string   "correlation_id"
    t.string   "time_stamp"
    t.string   "ack"
    t.string   "version"
    t.string   "build"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "pp_mp_errors", force: :cascade do |t|
    t.string   "correlation_id"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "producer_product_unit_commissions", force: :cascade do |t|
    t.integer  "product_id", null: false
    t.integer  "user_id",    null: false
    t.float    "commission", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "unit_id",    null: false
  end

  add_index "producer_product_unit_commissions", ["product_id"], name: "index_producer_product_unit_commissions_on_product_id"
  add_index "producer_product_unit_commissions", ["unit_id"], name: "index_producer_product_unit_commissions_on_unit_id"
  add_index "producer_product_unit_commissions", ["user_id"], name: "index_producer_product_unit_commissions_on_user_id"

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

  create_table "purchase_purchase_receivables", force: :cascade do |t|
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
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.float    "amount_purchased"
    t.integer  "kind"
    t.integer  "state",            default: 0
  end

  add_index "purchase_receivables", ["kind"], name: "index_purchase_receivables_on_kind"
  add_index "purchase_receivables", ["state"], name: "index_purchase_receivables_on_state"

  create_table "purchases", force: :cascade do |t|
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
    t.string   "payer_id"
    t.string   "transaction_id"
    t.text     "response"
    t.float    "gross_amount"
    t.float    "payment_processor_fee_withheld_from_us"
    t.float    "net_amount"
    t.float    "payment_processor_fee_withheld_from_producer", default: 0.0
    t.float    "commission",                                   default: 0.0
  end

  add_index "purchases", ["payer_id"], name: "index_purchases_on_payer_id"
  add_index "purchases", ["transaction_id"], name: "index_purchases_on_transaction_id"

  create_table "rtauthorizations", force: :cascade do |t|
    t.integer  "rtba_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "rtauthorizations", ["rtba_id"], name: "index_rtauthorizations_on_rtba_id"

  create_table "rtbas", force: :cascade do |t|
    t.string   "token",                      null: false
    t.string   "ba_id",                      null: false
    t.integer  "user_id",                    null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.boolean  "active",     default: false, null: false
  end

  add_index "rtbas", ["token"], name: "index_rtbas_on_token"
  add_index "rtbas", ["user_id"], name: "index_rtbas_on_user_id"

  create_table "rtpurchase_prs", id: false, force: :cascade do |t|
    t.integer  "rtpurchase_id"
    t.integer  "purchase_receivable_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "rtpurchase_prs", ["purchase_receivable_id"], name: "index_rtpurchase_prs_on_purchase_receivable_id"
  add_index "rtpurchase_prs", ["rtpurchase_id"], name: "index_rtpurchase_prs_on_rtpurchase_id"

  create_table "rtpurchases", force: :cascade do |t|
    t.boolean  "success"
    t.string   "message",                                      null: false
    t.string   "correlation_id",                               null: false
    t.string   "ba_id"
    t.float    "gross_amount"
    t.string   "ack"
    t.string   "error_codes"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.float    "payment_processor_fee_withheld_from_us"
    t.float    "payment_processor_fee_withheld_from_producer"
    t.string   "transaction_id"
  end

  create_table "subscription_rtauthorizations", id: false, force: :cascade do |t|
    t.integer  "rtauthorization_id"
    t.integer  "subscription_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "subscription_rtauthorizations", ["rtauthorization_id"], name: "index_subscription_rtauthorizations_on_rtauthorization_id"
  add_index "subscription_rtauthorizations", ["subscription_id"], name: "index_subscription_rtauthorizations_on_subscription_id"

  create_table "subscription_skip_dates", force: :cascade do |t|
    t.datetime "skip_date",       null: false
    t.integer  "subscription_id", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "subscription_skip_dates", ["skip_date"], name: "index_subscription_skip_dates_on_skip_date"
  add_index "subscription_skip_dates", ["subscription_id"], name: "index_subscription_skip_dates_on_subscription_id"

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "frequency",             default: 0,     null: false
    t.boolean  "on"
    t.integer  "user_id"
    t.integer  "posting_recurrence_id"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "quantity",                              null: false
    t.boolean  "paused",                default: false
  end

  add_index "subscriptions", ["posting_recurrence_id"], name: "index_subscriptions_on_posting_recurrence_id"
  add_index "subscriptions", ["user_id"], name: "index_subscriptions_on_user_id"

  create_table "tote_item_checkouts", id: false, force: :cascade do |t|
    t.integer  "tote_item_id"
    t.integer  "checkout_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "tote_item_checkouts", ["checkout_id"], name: "index_tote_item_checkouts_on_checkout_id"
  add_index "tote_item_checkouts", ["tote_item_id"], name: "index_tote_item_checkouts_on_tote_item_id"

  create_table "tote_item_rtauthorizations", id: false, force: :cascade do |t|
    t.integer  "tote_item_id"
    t.integer  "rtauthorization_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "tote_item_rtauthorizations", ["rtauthorization_id"], name: "index_tote_item_rtauthorizations_on_rtauthorization_id"
  add_index "tote_item_rtauthorizations", ["tote_item_id"], name: "index_tote_item_rtauthorizations_on_tote_item_id"

  create_table "tote_items", force: :cascade do |t|
    t.integer  "quantity"
    t.float    "price"
    t.integer  "state",           default: 0
    t.integer  "posting_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "user_id"
    t.integer  "subscription_id"
    t.datetime "authorized_at"
    t.integer  "quantity_filled", default: 0
  end

  add_index "tote_items", ["authorized_at"], name: "index_tote_items_on_authorized_at"
  add_index "tote_items", ["posting_id"], name: "index_tote_items_on_posting_id"
  add_index "tote_items", ["subscription_id"], name: "index_tote_items_on_subscription_id"
  add_index "tote_items", ["user_id"], name: "index_tote_items_on_user_id"

  create_table "units", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_account_states", id: false, force: :cascade do |t|
    t.integer  "account_state_id"
    t.integer  "user_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.text     "notes"
  end

  add_index "user_account_states", ["account_state_id"], name: "index_user_account_states_on_account_state_id"
  add_index "user_account_states", ["user_id"], name: "index_user_account_states_on_user_id"

  create_table "user_dropsites", id: false, force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "dropsite_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "user_dropsites", ["dropsite_id"], name: "index_user_dropsites_on_dropsite_id"
  add_index "user_dropsites", ["user_id"], name: "index_user_dropsites_on_user_id"

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

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "password_digest"
    t.integer  "account_type",      default: 0
    t.string   "remember_digest"
    t.string   "activation_digest"
    t.boolean  "activated",         default: false
    t.datetime "activated_at"
    t.string   "reset_digest"
    t.datetime "reset_sent_at"
    t.text     "description"
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "phone"
    t.string   "website"
    t.boolean  "agreement"
    t.boolean  "farmer_approval",   default: false
    t.string   "farm_name"
    t.boolean  "beta"
    t.integer  "zip"
    t.integer  "distributor_id"
    t.float    "order_minimum",     default: 0.0,   null: false
  end

  add_index "users", ["account_type"], name: "index_users_on_account_type"
  add_index "users", ["distributor_id"], name: "index_users_on_distributor_id"
  add_index "users", ["email"], name: "index_users_on_email", unique: true

  create_table "website_settings", force: :cascade do |t|
    t.boolean  "new_customer_access_code_required"
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.boolean  "recurring_postings_enabled",        default: false, null: false
  end

end
