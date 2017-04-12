class ReferenceTransactionsController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def new_ba

    response = GATEWAY.setup_authorization(
      0,
      billing_agreement: {
        type: 'MerchantInitiatedBillingSingleAgreement',
        description: 'Sample billing agreement'
      },
      ip: request.remote_ip,
      return_url: reference_transactions_create_ba_url,
      cancel_return_url: root_url,
      description: 'Sample',
      currency: 'USD',
      shipping: 0,
      handling: 0,
      tax: 0,
      allow_guest_checkout: true
      )    

    redirect_to GATEWAY.redirect_url_for(response.token)    

  end

  def create_ba

    @params = params
    @details = GATEWAY.details_for(params[:token])

    if @details.success?
      #this calls Paypal's CreateBillingAgreement API
      ba = GATEWAY.store(params[:token], {})
      if ba.success?
        PAYPALDATASTORE[:ba] = ba.authorization
        PAYPALDATASTORE[:token] = params[:token]
      end
    end
    
  end

  def create_capture

    amount = (params[:amount].to_f) * 100

    @details = GATEWAY.details_for(PAYPALDATASTORE[:token])
    @agreement_details = GATEWAY.agreement_details(PAYPALDATASTORE[:ba], {})

    @purchase = GATEWAY.reference_transaction(
      amount,
      reference_id: PAYPALDATASTORE[:ba],
      description: 'Sample',
      currency: 'USD',
      items: [{ name: 'Sample item', quantity: 1, amount: amount }]
    )   

  end

  def do_rtpurchase

    tote_items = [ToteItem.first, ToteItem.last]

    #create a purchase receivable object
    pr = create_purchase_receivable(tote_items)
    #make prs array
    prs = [pr]
    #create rtba object
    rtba = nil
    if current_user.rtbas.any? && current_user.rtbas.order("rtbas.id").last.active
      rtba = current_user.rtbas.order("rtbas.id").last
    else
      rtba = Rtba.new(user: current_user, token: "faketoken", ba_id: PAYPALDATASTORE[:ba], active: true)
      rtba.save
    end
    #create the rtauthorization object
    rtauthorization = nil
    if rtba.rtauthorizations.any?
      rtauthorization = rtba.rtauthorizations.order("rtauthorizations.id").last
    else
      #validates_presence_of :rtba, :tote_items
      rtauthorization = Rtauthorization.new(rtba: rtba)                
      ti = ToteItem.new(quantity: 1, price: 1, state: ToteItem.states[:COMMITTED], posting: Posting.first, user: current_user)
      ti.save
      rtauthorization.tote_items << ti
      rtauthorization.save
    end      

    #create rtpurchase object
    rtpurchase = Rtpurchase.new
    #call rtpurchase.go
    rtpurchase.go(rtauthorization, prs)
    rtpurchase.save

    redirect_to test_page_path

  end

  def do_bulk_purchase
    amount = 10

    #i just broke this working on another project. if you want to resurrect this some day you're going to need to send an array of tote items in rahter than an amount
    pr = create_purchase_receivable_for_bulk_purchase(amount)
    bulk_purchase = BulkPurchase.new(gross: 0, payment_processor_fee_withheld_from_us: 0, commission: 0, net: 0)
    bulk_purchase.load_unpurchased_receivables_for_users(User.all)
    bulk_purchase.go
    redirect_to test_page_path
  end

  private

    def create_purchase_receivable(tote_items)

      amount = get_gross_tote(tote_items)

      pr = PurchaseReceivable.new(amount: amount, amount_purchased: 0, kind: PurchaseReceivable.kind[:NORMAL], state: PurchaseReceivable.states[:READY])
      pr.users << current_user
      pr.tote_items = tote_items
      pr.save

      return pr
    end

    def create_purchase_receivable_for_bulk_purchase(amount)

      #PurchaseReceivable.update_all(kind: 1)
      
      pr = PurchaseReceivable.new(amount: amount, amount_purchased: 0, kind: PurchaseReceivable.kind[:NORMAL], state: PurchaseReceivable.states[:READY])
      pr.users << current_user
      ti = ToteItem.new(quantity: 1, price: 1, state: ToteItem.states[:COMMITTED], posting: Posting.first, user: current_user)
      ti.save
      pr.tote_items << ti

      rtba = nil
      if current_user.rtbas.any? && current_user.rtbas.order("rtbas.id").last.active
        rtba = current_user.rtbas.order("rtbas.id").last
      else
        rtba = Rtba.new(user: current_user, token: "faketoken", ba_id: PAYPALDATASTORE[:ba], active: true)
        rtba.save
      end
      #create the rtauthorization object
      rtauthorization = nil
      if rtba.rtauthorizations.any?
        rtauthorization = rtba.rtauthorizations.order("rtauthorizations.id").last
      else
        #validates_presence_of :rtba, :tote_items
        rtauthorization = Rtauthorization.new(rtba: rtba)
      end

      rtauthorization.tote_items << ti
      rtauthorization.save

      pr.save

      return pr

    end

end