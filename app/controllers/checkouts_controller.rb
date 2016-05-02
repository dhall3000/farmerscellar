class CheckoutsController < ApplicationController

  def create

    if params[:use_reference_transaction].nil?
      flash[:danger] = "Problem checking out. Please contact us if this persists."
      puts "CheckoutsController#create: unexpected form value for use_reference_transaction. value was nil."
    else
      if params[:use_reference_transaction].to_i == 1
        is_rt = true        
      elsif params[:use_reference_transaction].to_i == 0
        is_rt = false        
      else
        flash[:danger] = "Problem checking out. Please contact us if this persists."
        puts "CheckoutsController#create: unexpected form value for use_reference_transaction. was " + params[:use_reference_transaction].to_s
        redirect_to tote_items
        return
      end
      create_checkout(is_rt)
    end

  end

  private

    def create_checkout(is_rt)

      if current_user.dropsites.nil? || !current_user.dropsites.any?
        flash[:danger] = "Can't checkout until you specify a delivery dropsite."
        redirect_to dropsites_path
        return
      end

      if is_rt
        @checkout_tote_items = current_user_current_tote_items
      else
        @checkout_tote_items = current_user_current_unauthorized_tote_items
      end      

      if @checkout_tote_items == nil || !@checkout_tote_items.any?
        flash[:danger] = "Can't checkout until you have some product in your tote"
        redirect_to postings_path
        return
      end

      if USEGATEWAY

        options = {
            ip: request.remote_ip,                        
            cancel_return_url: tote_items_url,
            allow_guest_checkout: true,
            currency: 'USD'            
          }

        if is_rt
          money = 0
          options = options.merge({
            billing_agreement: {
              type: 'MerchantInitiatedBillingSingleAgreement',
              description: "Farmer's Cellar billing agreement"
            },
            return_url: rtauthorizations_new_url,
            description: "Farmer's Cellar billing agreement"
          })          
        else
          money = params[:amount].to_f * 100          
          options = options.merge({
              items: get_order_summary_details_for_paypal_display(@checkout_tote_items),
              return_url: new_authorization_url,
              description: "One time authorization"
            }
          )
        end

        response = GATEWAY.setup_authorization(money, options)        

      else
        response = FakeCheckoutResponse.new
      end

      @checkout = Checkout.new(token: response.token, amount: params[:amount].to_f, client_ip: request.remote_ip, response: response, is_rt: is_rt)

      @checkout_tote_items.each do |current_tote_item|
        @checkout.tote_items << current_tote_item
      end

      #save the AS to the db
      if @checkout.save
        if USEGATEWAY
          redirect_to GATEWAY.redirect_url_for(response.token)
        else                
          redirect_to(new_authorization_path(token: response.token))
        end
      else
        flash[:danger] = "Payment checkout error."
      end   

    end

    def get_order_summary_details_for_paypal_display(tote_items)
      summary_items = []

      if tote_items == nil || !tote_items.any?
        return summary_items
      end

      tote_items.each do |tote_item|
        summary_item = get_order_summary_item(tote_item)
        summary_items << summary_item
      end

      return summary_items
 
    end

    def get_order_summary_item(tote_item)
      summary_item = {}

      if tote_item == nil
        return summary_item
      end

      name = tote_item.posting.product.name
      description = "Producer - " + tote_item.posting.user.farm_name

      summary_item[:name] = name
      summary_item[:description] = description
      summary_item[:quantity] = tote_item.quantity
      summary_item[:amount] = (tote_item.price).round(2) * 100

      return summary_item
      
    end
end

class FakeCheckoutResponse
  attr_reader :token
  def initialize
    @token = ('a'..'z').to_a.shuffle[0..10].join
  end
end