module Spree
  class Gateway::PagSeguro < Gateway
    TEST_VISA = ['4242424242424242', '4012888888881881', '4222222222222']
    TEST_MC   = ['5500000000000004', '5555555555554444', '5105105105105100', '2223000010309703']
    TEST_AMEX = ['378282246310005', '371449635398431', '378734493671000', '340000000000009']
    TEST_DISC = ['6011000000000004', '6011111111111117', '6011000990139424']

    VALID_CCS = ['1', TEST_VISA, TEST_MC, TEST_AMEX, TEST_DISC].flatten

    attr_accessor :test

    def provider_class
      self.class
    end

    def preferences
      {}
    end

    def create_profile(payment)
      return if payment.source.has_payment_profile?

      # simulate the storage of credit card profile using remote service
      if success = VALID_CCS.include?(payment.source.number)
        payment.source.update(gateway_customer_profile_id: generate_profile_id(success))
      end
    end

    def authorize(_money, credit_card, _options = {})
      binding.pry if Rails.env.development?
      profile_id = credit_card.gateway_customer_profile_id

      

      # invoicing_url = OffsitePayments::Integrations::PagSeguro.invoicing_url
      # opt = { amount: 1100, forward_url: invoicing_url, checkout_token: 'D36CE9ABA6F74C119D764143C5849E15', credential2: 'D36CE9ABA6F74C119D764143C5849E15' }
      # helper = OffsitePayments::Integrations::PagSeguro::Helper.new(_options[:order_id], _options[:customer], opt)

      # if VALID_CCS.include?(credit_card.number) || (profile_id&.starts_with?('PAGS-'))
      if (profile_id&.starts_with?('PAGS-'))
        ActiveMerchant::Billing::Response.new(true, 'PagSeguro Gateway: Forced success', {}, test: true, authorization: '12345', avs_result: { code: 'D' })
      else
        ActiveMerchant::Billing::Response.new(false, 'PagSeguro Gateway: Forced failure', { message: 'PagSeguro Gateway: Forced failure' }, test: true)
      end
    end

    def purchase(_money, credit_card, _options = {})
      binding.pry if Rails.env.development?
      profile_id = credit_card.gateway_customer_profile_id
      payment = build_pagseguro_payment(_money, credit_card, _options)

      if VALID_CCS.include?(credit_card.number) || (profile_id&.starts_with?('PAGS-'))
        ActiveMerchant::Billing::Response.new(true, 'PagSeguro Gateway: Forced success', {}, test: true, authorization: '12345', avs_result: { code: 'M' })
      else
        ActiveMerchant::Billing::Response.new(false, 'PagSeguro Gateway: Forced failure', message: 'PagSeguro Gateway: Forced failure', test: true)
      end
    end

    def credit(_money, _credit_card, _response_code, _options = {})
      ActiveMerchant::Billing::Response.new(true, 'PagSeguro Gateway: Forced success', {}, test: true, authorization: '12345')
    end

    def capture(_money, authorization, _gateway_options)
      binding.pry if Rails.env.development?

      payment = build_pagseguro_payment(_money, authorization, _gateway_options)
      response = payment.register
    
      if response.errors.any?
        raise response.errors.join("\n")
      else   
        redirect_to response.url
      end

      if authorization == '12345' && response.errors.blank?
        ActiveMerchant::Billing::Response.new(true, 'PagSeguro Gateway: Forced success', {}, test: true)
      else
        ActiveMerchant::Billing::Response.new(false, 'PagSeguro Gateway: Forced failure', error: response.errors.join("\n"), test: true)
      end
    end

    def void(_response_code, _credit_card, _options = {})
      ActiveMerchant::Billing::Response.new(true, 'PagSeguro Gateway: Forced success', {}, test: true, authorization: '12345')
    end

    def cancel(_response_code)
      ActiveMerchant::Billing::Response.new(true, 'PagSeguro Gateway: Forced success', {}, test: true, authorization: '12345')
    end

    def test?
      # Test mode is not really relevant with PagSeguro gateway (no such thing as live server)
      true
    end

    def payment_profiles_supported?
      true
    end

    def actions
      %w(capture void credit)
    end

    private

    def build_pagseguro_payment(_money, _credit_card, options = {})
      order_id = options[:order_id]
      current_order = Spree::Order.find_by_number(order_id.split('-')[0])

      payment = Object::PagSeguro::PaymentRequest.new

      current_order.line_items.each do |item|
        amount = (item.price.to_f * 100).to_i
        quantity = item.quantity

        # Hash tem que ser tem que ser exatamente essas
        payment.items << { id: item.product.id, description: item.product.name, amount: amount, quantity: quantity }
      end

      payment.extra_params << options[:customer]
      payment
    end

    def generate_profile_id(success)
      record = true
      prefix = success ? 'PAGS' : 'FAIL'
      while record
        random = "#{prefix}-#{Array.new(6) { rand(6) }.join}"
        record = CreditCard.find_by(gateway_customer_profile_id: random)
      end
      random
    end
  end
end