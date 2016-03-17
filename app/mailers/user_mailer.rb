class UserMailer < ApplicationMailer
  include ToteItemsHelper

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
    mail to: user.email, subject: "Payment authorization receipt"
  end

  def delivery_notification(user, dropsite, tote_items)
    @user = user
    @dropsite = dropsite
    @tote_items = tote_items        

    @total_cost_of_tote_items = 0
    auths = []

    tote_items.each do |tote_item|

      if !tote_item.nil? && !tote_item.checkouts.nil? && tote_item.checkouts.any? && !tote_item.checkouts.last.authorizations.nil? && tote_item.checkouts.last.authorizations.any?
        auths << tote_item.checkouts.last.authorizations.last.id
      end

      #this 'if' block doesn't make sense any more. it did make sense when we always executed purchases immediately prior to dropsite delivery
      #but, of course, what we're going with now is delayed purchasing to minimize paypal fees so toteitems will never be PURCHASED at this point in the code
      if tote_item.status == ToteItem.states[:PURCHASED]        
        @total_cost_of_tote_items += get_gross_item(tote_item)
      end

    end    

    @authorizations = Authorization.find(auths.uniq)

    mail to: user.email, subject: "Delivery notification"
  end
  
end
