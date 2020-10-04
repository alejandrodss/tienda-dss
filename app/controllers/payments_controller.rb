class PaymentsController < ApplicationController

  def show; end
  def new; end

  def create
    @resp = PaymentCreator.new(payment_create_params).execute
    puts @resp.inspect
  end

  private
  def payment_create_params
    {value: params.dig(:payment, :product_quantity).to_f * 100, request: {ip: request.remote_ip}}
  end
end
