Spree::PaymentMethod.class_eval do

  # Scopes
  scope :afterpay, -> { where(type: 'Spree::Gateway::AfterpayPayments') }

  # Instance Methods
  def afterpay?
    type == 'Spree::Gateway::AfterpayPayments'
  end

end
