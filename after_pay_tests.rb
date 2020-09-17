@order = Spree::Order.find(932119)
payment_method = Spree::PaymentMethod.find(20)
@order.payments.create!({
  source: Spree::Afterpay.create({
    payment_method_id: payment_method['id']
  }),
  amount: @order.total,
  state: 'checkout',
  payment_method: payment_method,
})

@afterpay_source = @order.checkout_afterpay_payments.last.try(:source)

@afterpay_source.checkout(@order.outstanding_balance - @order.total_applied_store_credit, currency: 'USD', auto_capture: true)
