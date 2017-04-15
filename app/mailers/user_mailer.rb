class UserMailer < ApplicationMailer
  include ToteItemsHelper
  helper :tote_items

  def posting_alert(user, subject, body)
    @user = user
    @body = body
    mail to: user.email, subject: subject
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.account_activation.subject
  #
  def account_activation(user)
    @user = user
    mail to: user.email, subject: "Account activation"
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.password_reset.subject
  #
  def password_reset(user)
    @user = user
    mail to: user.email, subject: "Password reset"
  end

  #the 'authorization' param can be either a Authorization or a Rtauthorization
  def authorization_receipt(user, authorization, tote_items_getting_authorized = nil, subscriptions = nil)

    if tote_items_getting_authorized
      @amount = get_gross_tote(tote_items_getting_authorized)
      @link = rtauthorization_url(authorization, rta: 1)
    else
      @amount = authorization.amount
      @link = rtauthorization_url(authorization)
    end

    mail to: user.email, subject: "Authorization receipt"

  end

  def delivery_notification(user, dropsite, tote_items, partner_name = nil)

    #xunrfomunchfve (string search this string for more info)
    if partner_name.nil? && !any_items_filled?(tote_items)
      return
    end

    @user = user
    @dropsite = dropsite
    @tote_items = tote_items
    @partner_name = partner_name
    
    if partner_name
      subject = partner_name + " delivery notification"
    else
      subject = "Delivery notification"
    end

    mail to: user.email, subject: subject
  end

  def purchase_receipt(user, tote_items)
    @user = user
    @purchase_total = get_purchase_total(tote_items)
    @authorizations = get_auths(tote_items)
    @tote_items = tote_items
    
    mail to: @user.email, subject: "Purchase receipt"
  end

  def pickup_deadline_reminder(user, filled_tote_items, partner_deliveries)
    
    @user = user
    @tote_items = filled_tote_items
    @partner_deliveries = partner_deliveries

    if @user && @user.email
      if (@tote_items && @tote_items.any?) || (partner_deliveries && partner_deliveries.any?)
        mail to: @user.email, subject: "Pickup deadline reminder"
      end
    end

  end

  private

    def get_auths(tote_items)

      if tote_items == nil || !tote_items.any?
        return []
      end

      auths = []

      tote_items.each do |tote_item|

        if !tote_item.nil?
          auth = tote_item.authorization
          if !auth.nil?
            auths << auth
          end
        end
      
      end    

      return Authorization.where(id: auths.uniq)

    end

    def get_purchase_total(tote_items)

      if tote_items == nil || !tote_items.any?
        return 0
      end

      purchase_total = 0

      tote_items.each do |tote_item|

        pr = tote_item.purchase_receivables.order("purchase_receivables.id").last

        if pr.kind == PurchaseReceivable.kind[:NORMAL] && pr.state == PurchaseReceivable.states[:COMPLETE]        
          purchase_total = (purchase_total + get_gross_item(tote_item, filled = true)).round(2)
        end

      end    

      return purchase_total

    end
  
end
