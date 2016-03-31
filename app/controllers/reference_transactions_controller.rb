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

  	details = GATEWAY.details_for(params[:token])

  	if details.success?
  		#this calls Paypal's CreateBillingAgreement API
  		ba = GATEWAY.store(params[:token], {})
  		if ba.success?
  			PAYPALDATASTORE[:ba] = ba.authorization
  		end
  	end
  	
  end

  def create_capture

  	amount = (params[:amount].to_f) * 100

		purchase = GATEWAY.reference_transaction(
		  amount,
		  reference_id: PAYPALDATASTORE[:ba],
		  description: 'Sample',
		  currency: 'USD',
		  items: [{ name: 'Sample item', quantity: 1, amount: amount }]
		)		

  end
  
end
