module OffsitePayments::Integrations::Paypal
    # Module for configuring gateway-wide stuff, for example self.service_url, maybe accessors to Helper and Notification class instances

    class Helper < OffsitePayments::Helper
        # Class for creating a payment form on our site, that on submit will lead to Paypal, where clicking user will sign in and agree on money withdrawal.
    end

    class Notification < OffsitePayments::Notification
        # Class for handling Paypal's request to our site, telling us how payment went
    end
end