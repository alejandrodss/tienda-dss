class PaymentCreator
  attr_reader :params
  def initialize(params)
    @params = params
  end

  def execute
    create_payment
    resp = create_payment_request
    if resp.code.eql? '201'
      update_payment(resp)
      {success: true, payment_url: @payment.payment_url, error: nil }
    else
      puts "*"*99
      data = JSON.parse(resp.body)
      puts data.inspect
      {success: false, error: resp.code}
    end
  end

  private

  def create_payment
    attrs = {
      status: :unresolved,
      value: params[:value],
      description: 'Compra en Tienda DSS',
      code: Digest::SHA256.hexdigest("#{Time.current}-#{params[:value]}")
    }
    @payment = Payment.create(attrs)
  end

  def update_payment(resp)
    data = JSON.parse(resp.body)
    @payment.update(status: :created,
                    purchase_details_url: data["purchase_details_url"],
                    payment_url: data["tpaga_payment_url"],
                    token: data["token"])
  end

  def create_payment_request
    uri = URI('https://stag.wallet.tpaga.co/merchants/api/v1/payment_requests/create')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, header_request)
    request.set_form_data(body_request)
    response = http.request(request)
  end

  def header_request
    {'Authorization'=>'Basic bWluaWFwcG1hLW1pbmltYWw6YWJjMTIz',
    'Cache-Control' => 'no-cache',
    'Content-Type' => 'application/json'}
  end

  def body_request
      {"cost" => @payment.value.to_i,
      "purchase_details_url" => "https://tiendadss.com/payments/#{@payment.code}",
      "idempotency_token" => @payment.code,
      "order_id" => @payment.code,
      "terminal_id" => "pp_18",
      "purchase_description" => @payment.description,
      "user_ip_address" => params.dig(:request, :ip),
      "expires_at" => (Time.current + 3.days).strftime("%Y-%m-%d")}
  end
end
