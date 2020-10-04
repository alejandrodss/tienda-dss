require 'rails_helper'

RSpec.describe PaymentCreator do
  describe "#execute" do
    before do
      travel_to Time.new(2020, 10, 2, 18, 9, 9, "+00:00")
    end
    after do
      travel_back
    end

    let(:params) {{value: 50000, request: {ip: "127.168.0.1"}}.with_indifferent_access}
    let(:body) do
      {"cost" => "50000",
      "purchase_details_url" => "https://tiendadss.com/payments/113d19d68449759fd210f2a6448f4828a14834a6b215774a0857d8675932cace",
      "idempotency_token" => "113d19d68449759fd210f2a6448f4828a14834a6b215774a0857d8675932cace",
      "order_id" => "113d19d68449759fd210f2a6448f4828a14834a6b215774a0857d8675932cace",
      "terminal_id" => "pp_18",
      "purchase_description" => "Compra en Tienda DSS",
      "user_ip_address" => "127.168.0.1",
      "expires_at" => "2020-10-05"}
    end
    context "The request is successful" do
      it "Create payment request" do
        expected_response = {
          "cancelled_at" => "somestring",
          "cost" => "50000",
          "expires_at" => "2018-11-05",
          "idempotency_token" => "113d19d68449759fd210f2a6448f4828a14834a6b215774a0857d8675932cace",
          "merchant_user_id" => "somestring",
          "order_id" => "113d19d68449759fd210f2a6448f4828a14834a6b215774a0857d8675932cace",
          "purchase_description" => "Compra en Tienda DSS",
          "purchase_details_url" => "https://tiendadss.com/payment/113d19d68449759fd210f2a6448f4828a14834a6b215774a0857d8675932cace",
          "purchase_items" => {},
          "status" => "created",
          "terminal_id" => "pp_18",
          "token" => "pr-39394abaed1d3e97d1fe67423079c36336905671bb5a77877e3b9dc032a3070c52162365",
          "tpaga_payment_url" => "https://w.tpaga.co/eyJtIjp7Im8iOiJQUiJ9LCJkIjp7InMiOiJtaW5pbWFsLW1hIiwicHJ0IjoicHItMzkzOTRhYmFlZDFkM2U5N2QxZmU2NzQyMzA3OWMzNjMzNjkwNTY3MWJiNWE3Nzg3N2UzYjlkYzAzMmEzMDcwYzUyMTYyMzY1In19",
          "user_ip_address" => "127.168.0.1",
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

        response = described_class.new(params).execute

        expect(response).to eq({success: true, payment_url: "https://w.tpaga.co/eyJtIjp7Im8iOiJQUiJ9LCJkIjp7InMiOiJtaW5pbWFsLW1hIiwicHJ0IjoicHItMzkzOTRhYmFlZDFkM2U5N2QxZmU2NzQyMzA3OWMzNjMzNjkwNTY3MWJiNWE3Nzg3N2UzYjlkYzAzMmEzMDcwYzUyMTYyMzY1In19", error: nil})

        payments.reload
        expect(payments.count).to eq 1
        payment =  Payment.last
        expect(payment.status).to eq "created"
        expect(payment.value).to eq 50000
        expect(payment.purchase_details_url).to eq "https://tiendadss.com/payment/113d19d68449759fd210f2a6448f4828a14834a6b215774a0857d8675932cace"
        expect(payment.payment_url).to eq "https://w.tpaga.co/eyJtIjp7Im8iOiJQUiJ9LCJkIjp7InMiOiJtaW5pbWFsLW1hIiwicHJ0IjoicHItMzkzOTRhYmFlZDFkM2U5N2QxZmU2NzQyMzA3OWMzNjMzNjkwNTY3MWJiNWE3Nzg3N2UzYjlkYzAzMmEzMDcwYzUyMTYyMzY1In19"
        expect(payment.token).to eq "pr-39394abaed1d3e97d1fe67423079c36336905671bb5a77877e3b9dc032a3070c52162365"
      end
    end
    context "The request is not successful" do
      context "The request is unathorized" do
        it "Do not create payment request and return error response" do
          stub_request(:post, 'https://stag.wallet.tpaga.co/merchants/api/v1/payment_requests/create').
            with(headers: {'Authorization'=>'Basic bWluaWFwcG1hLW1pbmltYWw6YWJjMTIz',
                          'Cache-Control' => 'no-cache',
                          'Content-Type' => 'application/x-www-form-urlencoded',
                          'Accept'=>'*/*',
                          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                          'User-Agent'=>'Ruby'},
                body: body).to_return(status: 401, body: '', headers: {})
          payments = Payment.all
          expect(payments.count).to eq 0

          response = described_class.new(params).execute

          expect(response).to eq({success: false, error: "401"})

          payments.reload
          expect(payments.count).to eq 1
          payment =  Payment.last
          expect(payment.status).to eq "unresolved"
          expect(payment.value).to eq 50000
          expect(payment.purchase_details_url).to eq ""
          expect(payment.payment_url).to eq ""
          expect(payment.token).to eq nil
        end
      end
      context "The product was disabled" do
        it "Do not create payment request and return error response" do
          stub_request(:post, 'https://stag.wallet.tpaga.co/merchants/api/v1/payment_requests/create').
            with(headers: {'Authorization'=>'Basic bWluaWFwcG1hLW1pbmltYWw6YWJjMTIz',
                          'Cache-Control' => 'no-cache',
                          'Content-Type' => 'application/x-www-form-urlencoded',
                          'Accept'=>'*/*',
                          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                          'User-Agent'=>'Ruby'},
                body: body).to_return(status: 403, body: '{"error_code": 1}', headers: {})
          payments = Payment.all
          expect(payments.count).to eq 0

          response = described_class.new(params).execute

          expect(response).to eq({success: false, error: "403"})

          payments.reload
          expect(payments.count).to eq 1
          payment =  Payment.last
          expect(payment.status).to eq "unresolved"
          expect(payment.value).to eq 50000
          expect(payment.purchase_details_url).to eq ""
          expect(payment.payment_url).to eq ""
          expect(payment.token).to eq nil
        end
      end
      context "The payment request is already created" do
        it "Do not create payment request and return error response" do
          stub_request(:post, 'https://stag.wallet.tpaga.co/merchants/api/v1/payment_requests/create').
            with(headers: {'Authorization'=>'Basic bWluaWFwcG1hLW1pbmltYWw6YWJjMTIz',
                          'Cache-Control' => 'no-cache',
                          'Content-Type' => 'application/x-www-form-urlencoded',
                          'Accept'=>'*/*',
                          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                          'User-Agent'=>'Ruby'},
                body: body).to_return(status: 409, body: '{"error_code": 1, "data": {}}', headers: {})
          payments = Payment.all
          expect(payments.count).to eq 0

          response = described_class.new(params).execute

          expect(response).to eq({success: false, error: "409"})

          payments.reload
          expect(payments.count).to eq 1
          payment =  Payment.last
          expect(payment.status).to eq "unresolved"
          expect(payment.value).to eq 50000
          expect(payment.purchase_details_url).to eq ""
          expect(payment.payment_url).to eq ""
          expect(payment.token).to eq nil
        end
      end
      context "The payload is not valid" do
        it "Do not create payment request and return error response" do
          stub_request(:post, 'https://stag.wallet.tpaga.co/merchants/api/v1/payment_requests/create').
            with(headers: {'Authorization'=>'Basic bWluaWFwcG1hLW1pbmltYWw6YWJjMTIz',
                          'Cache-Control' => 'no-cache',
                          'Content-Type' => 'application/x-www-form-urlencoded',
                          'Accept'=>'*/*',
                          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                          'User-Agent'=>'Ruby'},
                body: body).to_return(status: 422, body: '{"error_code": 1, "error_message": ""}', headers: {})
          payments = Payment.all
          expect(payments.count).to eq 0

          response = described_class.new(params).execute

          expect(response).to eq({success: false, error: "422"})

          payments.reload
          expect(payments.count).to eq 1
          payment =  Payment.last
          expect(payment.status).to eq "unresolved"
          expect(payment.value).to eq 50000
          expect(payment.purchase_details_url).to eq ""
          expect(payment.payment_url).to eq ""
          expect(payment.token).to eq nil
        end
      end
    end
  end
end
