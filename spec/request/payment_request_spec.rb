require 'rails_helper'

RSpec.describe "Do a payment request", type: :feature do
  before do
    travel_to Time.new(2020, 10, 2, 18, 9, 9, "+00:00")
  end
  after do
    travel_back
  end

  let(:body) do
    {"cost" => "1000",
    "purchase_details_url" => "https://tiendadss.com/payments/49caad30a30fe78512cb07f9b71eb6cfb71e3c6aba44c320815336266387ac17",
    "idempotency_token" => "49caad30a30fe78512cb07f9b71eb6cfb71e3c6aba44c320815336266387ac17",
    "order_id" => "49caad30a30fe78512cb07f9b71eb6cfb71e3c6aba44c320815336266387ac17",
    "terminal_id" => "pp_18",
    "purchase_description" => "Compra en Tienda DSS",
    "user_ip_address" => "127.0.0.1",
    "expires_at" => "2020-10-05"}
  end

  context "An user select the product and make payment request" do
    context "The request is successful" do
      it "create a payment order" do
        expected_response = {
          "cancelled_at" => "somestring",
          "cost" => "5000",
          "expires_at" => "2018-11-05",
          "idempotency_token" => "49caad30a30fe78512cb07f9b71eb6cfb71e3c6aba44c320815336266387ac17",
          "merchant_user_id" => "somestring",
          "order_id" => "49caad30a30fe78512cb07f9b71eb6cfb71e3c6aba44c320815336266387ac17",
          "purchase_description" => "Compra en Tienda DSS",
          "purchase_details_url" => "https://tiendadss.com/payment/49caad30a30fe78512cb07f9b71eb6cfb71e3c6aba44c320815336266387ac17",
          "purchase_items" => {},
          "status" => "created",
          "terminal_id" => "pp_18",
          "token" => "pr-39394abaed1d3e97d1fe67423079c36336905671bb5a77877e3b9dc032a3070c52162365",
          "tpaga_payment_url" => "https://w.tpaga.co/eyJtIjp7Im8iOiJQUiJ9LCJkIjp7InMiOiJtaW5pbWFsLW1hIiwicHJ0IjoicHItMzkzOTRhYmFlZDFkM2U5N2QxZmU2NzQyMzA3OWMzNjMzNjkwNTY3MWJiNWE3Nzg3N2UzYjlkYzAzMmEzMDcwYzUyMTYyMzY1In19",
          "user_ip_address" => "127.0.0.1",
        }.to_json
        stub_request(:post, 'https://stag.wallet.tpaga.co/merchants/api/v1/payment_requests/create').
          with(headers: {'Authorization'=>'Basic bWluaWFwcG1hLW1pbmltYWw6YWJjMTIz',
                        'Cache-Control' => 'no-cache',
                        'Content-Type' => 'application/x-www-form-urlencoded',
                        'Accept'=>'*/*',
                        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                        'User-Agent'=>'Ruby'
                        },
              body: body).to_return(status: 201, body: expected_response, headers: {})
        payments = Payment.all
        expect(payments.count).to eq 0

        visit new_payment_path

        fill_in 'payment_product_quantity', with: 10
        click_button 'Pay with TPaga'

        expect(page).to have_content 'La generación de pago ha sido exitosa, para continuar ingresa al siguiente link:'
        expect(page).to have_selector('a.pay_link')

        payments.reload
        expect(payments.count).to eq 1
        payment =  payments.last
        expect(payment.status).to eq 'created'
        expect(payment.value).to eq 1000
        expect(payment.purchase_details_url).not_to eq nil
        expect(payment.token).not_to eq nil
      end
    end
    context "The request is not succesful" do
      it "do not create a payment order" do
        stub_request(:post, 'https://stag.wallet.tpaga.co/merchants/api/v1/payment_requests/create').
          with(headers: {'Authorization'=>'Basic bWluaWFwcG1hLW1pbmltYWw6YWJjMTIz',
                        'Cache-Control' => 'no-cache',
                        'Content-Type' => 'application/x-www-form-urlencoded',
                        'Accept'=>'*/*',
                        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                        'User-Agent'=>'Ruby'
                        },
              body: body).to_return(status: 401, body: '{}', headers: {})
        payments = Payment.all
        expect(payments.count).to eq 0

        visit new_payment_path

        fill_in 'payment_product_quantity', with: 10
        click_button 'Pay with TPaga'

        expect(page).not_to have_content 'La generación de pago ha sido exitosa, para continuar ingresa al siguiente link:'
        expect(page).not_to have_selector('a.pay_link')
        expect(page).to have_content 'Ha ocurrido un error al generar el pago, por favor intenta nuevamente, si el problema continua, contacta a nuestro equipo de soporte'

        payments.reload
        expect(payments.count).to eq 1
        payment =  payments.last
        expect(payment.status).to eq 'unresolved'
        expect(payment.value).to eq 1000
      end
    end
  end
end
