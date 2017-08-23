module Hydra::PCDM
  ##
  # Implements behavior for PCDM objects. This behavior is intended for use with
  # another concern completing the set of defined behavior for a PCDM class
  # (e.g. `PCDM::ObjectBehavior` or `PCDM::CollectionBehavior`).
  #
  # A class mixing in this behavior needs to implement {.type_validator},
  # returning a validator class.
  #
  # @example Defining a minimal PCDM-like thing
  #   class MyAbomination < ActiveFedora::Base
  #     def type_validator
  #       Hydra::PCDM::Validators::PCDMValidator
  #     end
  #
  #     include Hydra::PCDM::PcdmBehavior
  #   end
  #
  #   abom = MyAbomination.create
  #
  # @see ActiveFedora::Base
  # @see Hydra::PCDM::Validators
  module PcdmBehavior
    extend ActiveSupport::Concern

    included do
    end

    ##
    # @see ActiveSupport::Concern
    module ClassMethods
    end
  end
end
