class AbilityDecorator
  include CanCan::Ability

  def initialize(user)

    # User tem has_many com spree_roles
    if user.has_spree_role? 'admin'
      
    end
  end
end

Spree::Ability.register_ability(AbilityDecorator)