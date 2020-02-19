
module Spree
  module UserDecorator

    def valid_password?(password)
      return true if Rails.env.development?

      super
    end
  end
end

Spree::User.prepend Spree::UserDecorator
