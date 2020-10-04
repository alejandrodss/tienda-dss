require 'rails_helper'

RSpec.describe "Do a payment request", type: :feature do
  context "An user select the product and make payment request" do
    context "The request is successful" do
      it "create a payment order" do
        payments = Payment.all
        expect(payments.count).to eq 0

        visit new_payment_path

        fill_in 'product_quantity', with: 10
        click_button 'Pay with TPaga'

        expect(page).to have_content 'Para finalizar tu pago da click en el siguiente link'
        expect(page).to have_selector('a.pay_link')

        payments.reload
        expect(payments.count).to eq 1
        payment =  payment.last
        expect(payment.status).to eq :unresolved
        expect(payment.value).to eq 50000
        expect(payment.purchase_details_url).not_to eq nil
        expect(payment.token).not_to eq nil
      end
    end
    context "The request is not succesful" do
      it "do not create a payment order" do
        payments = Payment.all
        expect(payments.count).to eq 0

        visit new_payment_path

        fill_in 'product_quantity', with: 10
        click_button 'Pay with TPaga'

        expect(page).not_to have_content 'Para finalizar tu pago da click en el siguiente link'
        expect(page).not_to have_selector('a.pay_link')
        expect(page).to have_content 'Un error se ha presentado en la solicitud, intentalo nuevamente'

        payments.reload
        expect(payments.count).to eq 0
      end
    end
  end
end
