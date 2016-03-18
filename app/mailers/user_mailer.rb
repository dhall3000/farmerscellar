class UserMailer < ApplicationMailer
  include ToteItemsHelper
  helper :tote_items

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

  def authorization_receipt(user, authorization)
    @user = user
    @authorization = authorization
    mail to: user.email, subject: "Authorization receipt"
  end

  def delivery_notification(user, dropsite, tote_items)
    @user = user
    @dropsite = dropsite
    @tote_items = tote_items        

    @total_cost_of_tote_items = 0
    @authorizations = get_auths(tote_items)

    mail to: user.email, subject: "Delivery notification"
  end

  def purchase_receipt(user, tote_items)
    @user = user
    @purchase_total = get_purchase_total(tote_items)
    @authorizations = get_auths(tote_items)
    @tote_items = tote_items
    
    mail to: @user.email, subject: "Purchase receipt"
  end

  private

    def get_auths(tote_items)

      if tote_items == nil || !tote_items.any?
        return []
      end

      auths = []

      tote_items.each do |tote_item|

        if !tote_item.nil? && !tote_item.checkouts.nil? && tote_item.checkouts.any? && !tote_item.checkouts.last.authorizations.nil? && tote_item.checkouts.last.authorizations.any?
          auths << tote_item.checkouts.last.authorizations.last.id
        end
      
      end    

      return Authorization.find(auths.uniq)

    end

    def get_purchase_total(tote_items)

      if tote_items == nil || !tote_items.any?
        return 0
      end

      purchase_total = 0

      tote_items.each do |tote_item|      
        
        if tote_item.status == ToteItem.states[:PURCHASED]        
          purchase_total = (purchase_total + get_gross_item(tote_item)).round(2)
        end

      end    

      return purchase_total

    end
  
end
