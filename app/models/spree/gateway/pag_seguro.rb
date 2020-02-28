class Spree::Gateway::PagSeguro < Spree::Gateway

  def provider_class
    OffsitePayments::Integrations::PagSeguro
  end

  def payment_source_class
    provider_class::Helper
  end

  def method_type
    'pag_seguro'
  end

  def purchase(amount, transaction_details, options = {})
    binding.pry if Rails.env.development?
    ActiveMerchant::Billing::Response.new(true, 'success', {}, {})
  end
end