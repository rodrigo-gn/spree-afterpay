Spree::Payment.class_eval do

  #Scopes
  scope :afterpay, -> { joins(:payment_method).where(spree_payment_methods: { type: Spree::Gateway::AfterpayPayments.to_s }) }

end
