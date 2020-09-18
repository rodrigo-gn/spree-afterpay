module Spree
  class AfterpayController < ApplicationController

    include Spree::Core::ControllerHelpers::Order

    AFTERPAY_STATUS = {
      success: 'SUCCESS',
      cancelled: 'CANCELLED'
    }.freeze

    before_action :load_order, only: [:cancel, :success]
    before_action :validate_token, only: [:cancel, :success]
    before_action :validate_success_status, only: [:success]

    def checkout
      @order = current_order || raise(ActiveRecord::RecordNotFound)
      @order.checkout_afterpay_payments.map(&:invalidate!)
      create_afterpay_payment

      afterpay_source = @order.checkout_afterpay_payments.last.try(:source)
      if afterpay_source && afterpay_source.checkout(@order.outstanding_balance - @order.total_applied_store_credit, currency: current_currency, auto_capture: true)
        @token = afterpay_source.token
        render partial: 'spree/checkout/initialize_afterpay'
      else
        flash[:error] = Spree.t(:unable_to_checkout, scope: [:afterpay_payment_method])
        redirect_to checkout_state_path(@order.state)
      end
    end

    def success
      complete_order(Spree.t(:order_processed_successfully))
    end

    def cancel
      invalidate_afterpay_payment
      if params[:status] && params[:status] == AFTERPAY_STATUS[:cancelled]
        flash[:error] = Spree.t(:payment_cancelled, scope: [:afterpay])
      else
        flash[:error] = Spree.t(:payment_failed, scope: [:afterpay])
      end
      redirect_to checkout_state_path(@order.state)
    end

    private

    def create_afterpay_payment
      @order.payments.create!({
        source: Spree::Afterpay.create({
          payment_method_id: params[:payment_method_id]
        }),
        amount: @order.total,
        state: 'checkout',
        payment_method: payment_method,
      })
    end

    def payment_method
      @payment_method ||= Spree::PaymentMethod.afterpay.first
    end

    def validate_token
      unless params[:orderToken] == @order.payments&.afterpay.last&.source&.token
        redirect_to(spree.cart_path)
      end
    end

    def validate_success_status
      unless params[:status] && params[:status] == AFTERPAY_STATUS[:success]
        flash[:error] = Spree.t(:payment_failed, scope: [:afterpay])
        redirect_to checkout_state_path(@order.state)
      end
    end

    def completion_route
      spree.order_path(@order)
    end

    def load_order
      @order = Spree::Order.find_by(number: params[:id])

      unless @order.present? && @order.payment_total < @order.total
        redirect_to(spree.cart_path)
      end
    end

    def invalidate_afterpay_payment
      @order.checkout_afterpay_payments.map(&:invalidate!)
    end

    def complete_order(flash_message)
      unless @order.next
        flash[:error] = @order.errors.full_messages.join('\n')
        redirect_to(checkout_state_path(@order.state)) && return
      end

      if @order.completed?
        @current_order = nil
        flash[:notice] = flash_message
        flash[:order_completed] = true
        redirect_to completion_route
      else
        redirect_to checkout_state_path(@order.state)
      end
    end

  end
end
