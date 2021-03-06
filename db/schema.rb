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

ActiveRecord::Schema.define(version: 20170523194740) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_codes", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text     "notes"
    t.index ["user_id"], name: "index_access_codes_on_user_id", using: :btree
  end

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
    t.index ["bulk_buy_id"], name: "index_admin_bulk_buys_on_bulk_buy_id", using: :btree
    t.index ["user_id"], name: "index_admin_bulk_buys_on_user_id", using: :btree
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
    t.float    "amount_purchased"
    t.text     "response"
    t.string   "ack"
  end

  create_table "bp_pp_mp_commons", id: false, force: :cascade do |t|
    t.integer  "bulk_payment_id"
    t.integer  "pp_mp_common_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["bulk_payment_id"], name: "index_bp_pp_mp_commons_on_bulk_payment_id", using: :btree
    t.index ["pp_mp_common_id"], name: "index_bp_pp_mp_commons_on_pp_mp_common_id", using: :btree
  end

  create_table "bp_pp_mp_errors", id: false, force: :cascade do |t|
    t.integer  "bulk_payment_id"
    t.integer  "pp_mp_error_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["bulk_payment_id"], name: "index_bp_pp_mp_errors_on_bulk_payment_id", using: :btree
    t.index ["pp_mp_error_id"], name: "index_bp_pp_mp_errors_on_pp_mp_error_id", using: :btree
  end

  create_table "bulk_buy_purchase_receivables", id: false, force: :cascade do |t|
    t.integer  "purchase_receivable_id"
    t.integer  "bulk_buy_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["bulk_buy_id"], name: "index_bulk_buy_purchase_receivables_on_bulk_buy_id", using: :btree
    t.index ["purchase_receivable_id"], name: "index_bulk_buy_purchase_receivables_on_purchase_receivable_id", using: :btree
  end

  create_table "bulk_buy_tote_items", id: false, force: :cascade do |t|
    t.integer  "tote_item_id"
    t.integer  "bulk_buy_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["bulk_buy_id"], name: "index_bulk_buy_tote_items_on_bulk_buy_id", using: :btree
    t.index ["tote_item_id"], name: "index_bulk_buy_tote_items_on_tote_item_id", using: :btree
  end

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
    t.index ["bulk_payment_id"], name: "index_bulk_payment_payables_on_bulk_payment_id", using: :btree
    t.index ["payment_payable_id"], name: "index_bulk_payment_payables_on_payment_payable_id", using: :btree
  end

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
    t.index ["bulk_purchase_id"], name: "index_bulk_purchase_receivables_on_bulk_purchase_id", using: :btree
    t.index ["purchase_receivable_id"], name: "index_bulk_purchase_receivables_on_purchase_receivable_id", using: :btree
  end

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
    t.string   "name",                              null: false
    t.string   "order_email"
    t.string   "order_instructions"
    t.string   "paypal_email"
    t.integer  "user_id"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "payment_method",        default: 0, null: false
    t.integer  "payment_time",          default: 2, null: false
    t.string   "payment_receipt_email"
    t.index ["user_id"], name: "index_business_interfaces_on_user_id", using: :btree
  end

  create_table "checkout_authorizations", id: false, force: :cascade do |t|
    t.integer  "checkout_id"
    t.integer  "authorization_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["authorization_id"], name: "index_checkout_authorizations_on_authorization_id", using: :btree
    t.index ["checkout_id"], name: "index_checkout_authorizations_on_checkout_id", using: :btree
  end

  create_table "checkouts", force: :cascade do |t|
    t.string   "token"
    t.float    "amount"
    t.string   "client_ip"
    t.text     "response"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.boolean  "is_rt",      default: false
    t.index ["is_rt"], name: "index_checkouts_on_is_rt", using: :btree
    t.index ["token"], name: "index_checkouts_on_token", using: :btree
  end

  create_table "creditor_obligation_payment_payables", force: :cascade do |t|
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "creditor_obligation_id"
    t.integer  "payment_payable_id"
    t.index ["creditor_obligation_id"], name: "index_copp_on_co_id", using: :btree
    t.index ["payment_payable_id"], name: "index_copp_on_pp_id", using: :btree
  end

  create_table "creditor_obligation_payments", force: :cascade do |t|
    t.integer  "creditor_obligation_id"
    t.integer  "payment_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["creditor_obligation_id"], name: "index_creditor_obligation_payments_on_creditor_obligation_id", using: :btree
    t.index ["payment_id"], name: "index_creditor_obligation_payments_on_payment_id", using: :btree
  end

  create_table "creditor_obligations", force: :cascade do |t|
    t.integer  "creditor_order_id"
    t.float    "balance",           default: 0.0, null: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.index ["creditor_order_id"], name: "index_creditor_obligations_on_creditor_order_id", using: :btree
  end

  create_table "creditor_order_postings", force: :cascade do |t|
    t.integer  "creditor_order_id"
    t.integer  "posting_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.index ["creditor_order_id"], name: "index_creditor_order_postings_on_creditor_order_id", using: :btree
    t.index ["posting_id"], name: "index_creditor_order_postings_on_posting_id", using: :btree
  end

  create_table "creditor_orders", force: :cascade do |t|
    t.datetime "delivery_date"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.integer  "creditor_id"
    t.float    "order_value_producer_net", default: 0.0, null: false
    t.integer  "state",                    default: 0,   null: false
    t.index ["creditor_id"], name: "index_creditor_orders_on_creditor_id", using: :btree
    t.index ["delivery_date"], name: "index_creditor_orders_on_delivery_date", using: :btree
    t.index ["state"], name: "index_creditor_orders_on_state", using: :btree
  end

  create_table "deliveries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delivery_dropsites", id: false, force: :cascade do |t|
    t.integer  "delivery_id"
    t.integer  "dropsite_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["delivery_id"], name: "index_delivery_dropsites_on_delivery_id", using: :btree
    t.index ["dropsite_id"], name: "index_delivery_dropsites_on_dropsite_id", using: :btree
  end

  create_table "delivery_postings", id: false, force: :cascade do |t|
    t.integer  "posting_id"
    t.integer  "delivery_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["delivery_id"], name: "index_delivery_postings_on_delivery_id", using: :btree
    t.index ["posting_id"], name: "index_delivery_postings_on_posting_id", using: :btree
  end

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
    t.string   "ip_address"
  end

  create_table "email_recipients", force: :cascade do |t|
    t.integer  "email_id"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_id"], name: "index_email_recipients_on_email_id", using: :btree
    t.index ["user_id"], name: "index_email_recipients_on_user_id", using: :btree
  end

  create_table "emails", force: :cascade do |t|
    t.string   "subject",    null: false
    t.text     "body",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "send_time"
  end

  create_table "food_categories", force: :cascade do |t|
    t.string   "name",                      null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "parent_id"
    t.string   "sequence"
    t.boolean  "display",    default: true, null: false
    t.index ["name"], name: "index_food_categories_on_name", using: :btree
    t.index ["parent_id"], name: "index_food_categories_on_parent_id", using: :btree
  end

  create_table "food_category_uploads", force: :cascade do |t|
    t.integer  "food_category_id"
    t.integer  "upload_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["food_category_id"], name: "index_food_category_uploads_on_food_category_id", using: :btree
    t.index ["upload_id"], name: "index_food_category_uploads_on_upload_id", using: :btree
  end

  create_table "got_its", force: :cascade do |t|
    t.integer  "user_id"
    t.boolean  "delivery_date_range_selection"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.index ["user_id"], name: "index_got_its_on_user_id", using: :btree
  end

  create_table "nightly_task_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_values", force: :cascade do |t|
    t.float    "inbound_producer_net", default: 0.0, null: false
    t.datetime "order_cutoff",                       null: false
    t.integer  "user_id"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.index ["order_cutoff"], name: "index_order_values_on_order_cutoff", using: :btree
    t.index ["user_id"], name: "index_order_values_on_user_id", using: :btree
  end

  create_table "page_updates", force: :cascade do |t|
    t.string   "name"
    t.datetime "update_time"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["name"], name: "index_page_updates_on_name", using: :btree
  end

  create_table "partner_deliveries", force: :cascade do |t|
    t.string   "partner"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_partner_deliveries_on_user_id", using: :btree
  end

  create_table "payment_payable_payments", force: :cascade do |t|
    t.integer  "payment_payable_id"
    t.integer  "payment_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["payment_id"], name: "index_payment_payable_payments_on_payment_id", using: :btree
    t.index ["payment_payable_id"], name: "index_payment_payable_payments_on_payment_payable_id", using: :btree
  end

  create_table "payment_payable_tote_items", id: false, force: :cascade do |t|
    t.integer  "tote_item_id"
    t.integer  "payment_payable_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["payment_payable_id"], name: "index_payment_payable_tote_items_on_payment_payable_id", using: :btree
    t.index ["tote_item_id"], name: "index_payment_payable_tote_items_on_tote_item_id", using: :btree
  end

  create_table "payment_payables", force: :cascade do |t|
    t.float    "amount"
    t.float    "amount_paid"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.boolean  "fully_paid",  default: false, null: false
    t.index ["fully_paid"], name: "index_payment_payables_on_fully_paid", using: :btree
  end

  create_table "payments", force: :cascade do |t|
    t.float    "amount",         default: 0.0, null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.float    "amount_applied", default: 0.0, null: false
    t.text     "notes"
  end

  create_table "pickup_codes", force: :cascade do |t|
    t.string   "code",       null: false
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_pickup_codes_on_code", using: :btree
    t.index ["user_id"], name: "index_pickup_codes_on_user_id", using: :btree
  end

  create_table "pickups", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_pickups_on_user_id", using: :btree
  end

  create_table "posting_emails", force: :cascade do |t|
    t.integer  "posting_id"
    t.integer  "email_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_id"], name: "index_posting_emails_on_email_id", using: :btree
    t.index ["posting_id"], name: "index_posting_emails_on_posting_id", using: :btree
  end

  create_table "posting_recurrences", force: :cascade do |t|
    t.integer  "frequency",  default: 0,     null: false
    t.boolean  "on",         default: false, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "posting_uploads", force: :cascade do |t|
    t.integer  "posting_id"
    t.integer  "upload_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["posting_id"], name: "index_posting_uploads_on_posting_id", using: :btree
    t.index ["upload_id"], name: "index_posting_uploads_on_upload_id", using: :btree
  end

  create_table "postings", force: :cascade do |t|
    t.text     "description_body"
    t.float    "price",                            default: 0.0,   null: false
    t.integer  "user_id",                                          null: false
    t.integer  "product_id",                                       null: false
    t.integer  "unit_id",                                          null: false
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.boolean  "live",                             default: false, null: false
    t.datetime "delivery_date",                                    null: false
    t.datetime "order_cutoff",                                     null: false
    t.integer  "posting_recurrence_id"
    t.integer  "state",                            default: 0,     null: false
    t.string   "description",                                      null: false
    t.string   "price_body"
    t.string   "unit_body"
    t.integer  "units_per_case"
    t.string   "product_id_code"
    t.float    "order_minimum_producer_net"
    t.string   "important_notes"
    t.string   "important_notes_body"
    t.float    "inbound_order_value_producer_net", default: 0.0,   null: false
    t.float    "producer_net_unit",                default: 0.0,   null: false
    t.float    "refundable_deposit"
    t.text     "refundable_deposit_instructions"
    t.index ["delivery_date"], name: "index_postings_on_delivery_date", using: :btree
    t.index ["live"], name: "index_postings_on_live", using: :btree
    t.index ["order_cutoff"], name: "index_postings_on_order_cutoff", using: :btree
    t.index ["posting_recurrence_id"], name: "index_postings_on_posting_recurrence_id", using: :btree
    t.index ["product_id"], name: "index_postings_on_product_id", using: :btree
    t.index ["state"], name: "index_postings_on_state", using: :btree
    t.index ["unit_id"], name: "index_postings_on_unit_id", using: :btree
    t.index ["user_id"], name: "index_postings_on_user_id", using: :btree
  end

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

  create_table "products", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "food_category_id"
    t.index ["food_category_id"], name: "index_products_on_food_category_id", using: :btree
  end

  create_table "purchase_bulk_buys", id: false, force: :cascade do |t|
    t.integer  "purchase_id"
    t.integer  "bulk_buy_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["bulk_buy_id"], name: "index_purchase_bulk_buys_on_bulk_buy_id", using: :btree
    t.index ["purchase_id"], name: "index_purchase_bulk_buys_on_purchase_id", using: :btree
  end

  create_table "purchase_purchase_receivables", force: :cascade do |t|
    t.integer  "purchase_id"
    t.integer  "purchase_receivable_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["purchase_id"], name: "index_purchase_purchase_receivables_on_purchase_id", using: :btree
    t.index ["purchase_receivable_id"], name: "index_purchase_purchase_receivables_on_purchase_receivable_id", using: :btree
  end

  create_table "purchase_receivable_tote_items", id: false, force: :cascade do |t|
    t.integer  "tote_item_id"
    t.integer  "purchase_receivable_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["purchase_receivable_id"], name: "index_purchase_receivable_tote_items_on_purchase_receivable_id", using: :btree
    t.index ["tote_item_id"], name: "index_purchase_receivable_tote_items_on_tote_item_id", using: :btree
  end

  create_table "purchase_receivables", force: :cascade do |t|
    t.float    "amount"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.float    "amount_purchased"
    t.integer  "kind"
    t.integer  "state",            default: 0
    t.index ["kind"], name: "index_purchase_receivables_on_kind", using: :btree
    t.index ["state"], name: "index_purchase_receivables_on_state", using: :btree
  end

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
    t.index ["payer_id"], name: "index_purchases_on_payer_id", using: :btree
    t.index ["transaction_id"], name: "index_purchases_on_transaction_id", using: :btree
  end

  create_table "rtauthorizations", force: :cascade do |t|
    t.integer  "rtba_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rtba_id"], name: "index_rtauthorizations_on_rtba_id", using: :btree
  end

  create_table "rtbas", force: :cascade do |t|
    t.string   "token",                      null: false
    t.string   "ba_id",                      null: false
    t.integer  "user_id",                    null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.boolean  "active",     default: false, null: false
    t.index ["token"], name: "index_rtbas_on_token", using: :btree
    t.index ["user_id"], name: "index_rtbas_on_user_id", using: :btree
  end

  create_table "rtpurchase_prs", id: false, force: :cascade do |t|
    t.integer  "rtpurchase_id"
    t.integer  "purchase_receivable_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["purchase_receivable_id"], name: "index_rtpurchase_prs_on_purchase_receivable_id", using: :btree
    t.index ["rtpurchase_id"], name: "index_rtpurchase_prs_on_rtpurchase_id", using: :btree
  end

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

  create_table "settings", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_settings_on_user_id", using: :btree
  end

  create_table "subscription_rtauthorizations", id: false, force: :cascade do |t|
    t.integer  "rtauthorization_id"
    t.integer  "subscription_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["rtauthorization_id"], name: "index_subscription_rtauthorizations_on_rtauthorization_id", using: :btree
    t.index ["subscription_id"], name: "index_subscription_rtauthorizations_on_subscription_id", using: :btree
  end

  create_table "subscription_skip_dates", force: :cascade do |t|
    t.datetime "skip_date",       null: false
    t.integer  "subscription_id", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["skip_date"], name: "index_subscription_skip_dates_on_skip_date", using: :btree
    t.index ["subscription_id"], name: "index_subscription_skip_dates_on_subscription_id", using: :btree
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "frequency",             default: 0,     null: false
    t.boolean  "on"
    t.integer  "user_id"
    t.integer  "posting_recurrence_id"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "quantity",                              null: false
    t.boolean  "paused",                default: false
    t.integer  "kind",                  default: 0,     null: false
    t.index ["posting_recurrence_id"], name: "index_subscriptions_on_posting_recurrence_id", using: :btree
    t.index ["user_id"], name: "index_subscriptions_on_user_id", using: :btree
  end

  create_table "tote_item_checkouts", id: false, force: :cascade do |t|
    t.integer  "tote_item_id"
    t.integer  "checkout_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["checkout_id"], name: "index_tote_item_checkouts_on_checkout_id", using: :btree
    t.index ["tote_item_id"], name: "index_tote_item_checkouts_on_tote_item_id", using: :btree
  end

  create_table "tote_item_rtauthorizations", id: false, force: :cascade do |t|
    t.integer  "tote_item_id"
    t.integer  "rtauthorization_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["rtauthorization_id"], name: "index_tote_item_rtauthorizations_on_rtauthorization_id", using: :btree
    t.index ["tote_item_id"], name: "index_tote_item_rtauthorizations_on_tote_item_id", using: :btree
  end

  create_table "tote_items", force: :cascade do |t|
    t.integer  "quantity"
    t.float    "price"
    t.integer  "state",           default: 9, null: false
    t.integer  "posting_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "user_id"
    t.integer  "subscription_id"
    t.datetime "authorized_at"
    t.integer  "quantity_filled", default: 0
    t.index ["authorized_at"], name: "index_tote_items_on_authorized_at", using: :btree
    t.index ["posting_id"], name: "index_tote_items_on_posting_id", using: :btree
    t.index ["state"], name: "index_tote_items_on_state", using: :btree
    t.index ["subscription_id"], name: "index_tote_items_on_subscription_id", using: :btree
    t.index ["user_id"], name: "index_tote_items_on_user_id", using: :btree
  end

  create_table "units", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "uploads", force: :cascade do |t|
    t.string   "file_name"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.string   "title"
    t.integer  "square_size", default: 0
    t.integer  "large_size",  default: 0
    t.index ["title"], name: "index_uploads_on_title", unique: true, using: :btree
  end

  create_table "user_account_states", id: false, force: :cascade do |t|
    t.integer  "account_state_id"
    t.integer  "user_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.text     "notes"
    t.index ["account_state_id"], name: "index_user_account_states_on_account_state_id", using: :btree
    t.index ["user_id"], name: "index_user_account_states_on_user_id", using: :btree
  end

  create_table "user_dropsites", id: false, force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "dropsite_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["dropsite_id"], name: "index_user_dropsites_on_dropsite_id", using: :btree
    t.index ["user_id"], name: "index_user_dropsites_on_user_id", using: :btree
  end

  create_table "user_payment_payables", id: false, force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "payment_payable_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["payment_payable_id"], name: "index_user_payment_payables_on_payment_payable_id", using: :btree
    t.index ["user_id"], name: "index_user_payment_payables_on_user_id", using: :btree
  end

  create_table "user_purchase_receivables", id: false, force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "purchase_receivable_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["purchase_receivable_id"], name: "index_user_purchase_receivables_on_purchase_receivable_id", using: :btree
    t.index ["user_id"], name: "index_user_purchase_receivables_on_user_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "password_digest"
    t.integer  "account_type",               default: 0
    t.string   "remember_digest"
    t.string   "activation_digest"
    t.boolean  "activated",                  default: false
    t.datetime "activated_at"
    t.string   "reset_digest"
    t.datetime "reset_sent_at"
    t.text     "description"
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "phone"
    t.string   "website"
    t.string   "farm_name"
    t.boolean  "beta"
    t.integer  "zip"
    t.integer  "distributor_id"
    t.float    "order_minimum_producer_net", default: 0.0,   null: false
    t.boolean  "partner_user",               default: false
    t.boolean  "header_data_dirty",          default: true
    t.datetime "last_whats_new_view"
    t.index ["account_type"], name: "index_users_on_account_type", using: :btree
    t.index ["distributor_id"], name: "index_users_on_distributor_id", using: :btree
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
  end

  create_table "website_settings", force: :cascade do |t|
    t.boolean  "new_customer_access_code_required"
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.boolean  "recurring_postings_enabled",        default: false, null: false
  end

  add_foreign_key "access_codes", "users"
  add_foreign_key "admin_bulk_buys", "bulk_buys"
  add_foreign_key "admin_bulk_buys", "users"
  add_foreign_key "bp_pp_mp_commons", "bulk_payments"
  add_foreign_key "bp_pp_mp_commons", "pp_mp_commons"
  add_foreign_key "bp_pp_mp_errors", "bulk_payments"
  add_foreign_key "bp_pp_mp_errors", "pp_mp_errors"
  add_foreign_key "bulk_buy_purchase_receivables", "bulk_buys"
  add_foreign_key "bulk_buy_purchase_receivables", "purchase_receivables"
  add_foreign_key "bulk_buy_tote_items", "bulk_buys"
  add_foreign_key "bulk_buy_tote_items", "tote_items"
  add_foreign_key "bulk_payment_payables", "bulk_payments"
  add_foreign_key "bulk_payment_payables", "payment_payables"
  add_foreign_key "bulk_purchase_receivables", "bulk_purchases"
  add_foreign_key "bulk_purchase_receivables", "purchase_receivables"
  add_foreign_key "business_interfaces", "users"
  add_foreign_key "checkout_authorizations", "authorizations"
  add_foreign_key "checkout_authorizations", "checkouts"
  add_foreign_key "creditor_obligation_payment_payables", "creditor_obligations"
  add_foreign_key "creditor_obligation_payment_payables", "payment_payables"
  add_foreign_key "creditor_obligation_payments", "creditor_obligations"
  add_foreign_key "creditor_obligation_payments", "payments"
  add_foreign_key "creditor_obligations", "creditor_orders"
  add_foreign_key "creditor_order_postings", "creditor_orders"
  add_foreign_key "creditor_order_postings", "postings"
  add_foreign_key "creditor_orders", "users", column: "creditor_id"
  add_foreign_key "delivery_dropsites", "deliveries"
  add_foreign_key "delivery_dropsites", "dropsites"
  add_foreign_key "delivery_postings", "deliveries"
  add_foreign_key "delivery_postings", "postings"
  add_foreign_key "email_recipients", "emails"
  add_foreign_key "email_recipients", "users"
  add_foreign_key "food_categories", "food_categories", column: "parent_id"
  add_foreign_key "food_category_uploads", "food_categories"
  add_foreign_key "food_category_uploads", "uploads"
  add_foreign_key "got_its", "users"
  add_foreign_key "order_values", "users"
  add_foreign_key "partner_deliveries", "users"
  add_foreign_key "payment_payable_payments", "payment_payables"
  add_foreign_key "payment_payable_payments", "payments"
  add_foreign_key "payment_payable_tote_items", "payment_payables"
  add_foreign_key "payment_payable_tote_items", "tote_items"
  add_foreign_key "pickup_codes", "users"
  add_foreign_key "pickups", "users"
  add_foreign_key "posting_emails", "emails"
  add_foreign_key "posting_emails", "postings"
  add_foreign_key "posting_uploads", "postings"
  add_foreign_key "posting_uploads", "uploads"
  add_foreign_key "postings", "posting_recurrences"
  add_foreign_key "postings", "products"
  add_foreign_key "postings", "units"
  add_foreign_key "postings", "users"
  add_foreign_key "products", "food_categories"
  add_foreign_key "purchase_bulk_buys", "bulk_buys"
  add_foreign_key "purchase_bulk_buys", "purchases"
  add_foreign_key "purchase_purchase_receivables", "purchase_receivables"
  add_foreign_key "purchase_purchase_receivables", "purchases"
  add_foreign_key "purchase_receivable_tote_items", "purchase_receivables"
  add_foreign_key "purchase_receivable_tote_items", "tote_items"
  add_foreign_key "rtauthorizations", "rtbas"
  add_foreign_key "rtbas", "users"
  add_foreign_key "rtpurchase_prs", "purchase_receivables"
  add_foreign_key "rtpurchase_prs", "rtpurchases"
  add_foreign_key "settings", "users"
  add_foreign_key "subscription_rtauthorizations", "rtauthorizations"
  add_foreign_key "subscription_rtauthorizations", "subscriptions"
  add_foreign_key "subscription_skip_dates", "subscriptions"
  add_foreign_key "subscriptions", "posting_recurrences"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "tote_item_checkouts", "checkouts"
  add_foreign_key "tote_item_checkouts", "tote_items"
  add_foreign_key "tote_item_rtauthorizations", "rtauthorizations"
  add_foreign_key "tote_item_rtauthorizations", "tote_items"
  add_foreign_key "tote_items", "postings"
  add_foreign_key "tote_items", "subscriptions"
  add_foreign_key "tote_items", "users"
  add_foreign_key "user_account_states", "account_states"
  add_foreign_key "user_account_states", "users"
  add_foreign_key "user_dropsites", "dropsites"
  add_foreign_key "user_dropsites", "users"
  add_foreign_key "user_payment_payables", "payment_payables"
  add_foreign_key "user_payment_payables", "users"
  add_foreign_key "user_purchase_receivables", "purchase_receivables"
  add_foreign_key "user_purchase_receivables", "users"
  add_foreign_key "users", "users", column: "distributor_id"
end
