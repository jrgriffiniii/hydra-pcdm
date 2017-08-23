module Hydra::PCDM
  ##
  # Implements behavior for PCDM collections.
  #
  # The behavior is summarized as:
  #   1) Hydra::PCDM::Collection can aggregate (pcdm:hasMember)  Hydra::PCDM::Collection (no infinite loop, e.g., A -> B -> C -> A)
  #   2) Hydra::PCDM::Collection can aggregate (pcdm:hasMember)  Hydra::PCDM::Object
  #   3) Hydra::PCDM::Collection can aggregate (ore:aggregates) Hydra::PCDM::Object  (Object related to the Collection)
  #   4) Hydra::PCDM::Collection can NOT aggregate non-PCDM object
  #   5) Hydra::PCDM::Collection can NOT contain (pcdm:hasFile)  Hydra::PCDM::File
  #   6) Hydra::PCDM::Collection can have descriptive metadata
  #   7) Hydra::PCDM::Collection can have access metadata
  #
  module CollectionBehavior
    extend ActiveSupport::Concern

    included do
      include Hydra::PCDM::PcdmBehavior
      type Vocab::PCDMTerms.Collection
      ##
      # @macro [new] ordered_aggregation
      #   @!method $1
      #     @return [ActiveFedora::Associations::ContainerProxy]
      ordered_aggregation :members,
                          has_member_relation: Vocab::PCDMTerms.hasMember,
                          class_name: 'ActiveFedora::Base',
                          type_validator: type_validator,
                          through: :list_source

      ##
      # @macro [new] indirectly_contains
      #   @!method $1
      #     @return [ActiveFedora::Associations::ContainerProxy]
      indirectly_contains :related_objects,
                          has_member_relation: RDF::Vocab::ORE.aggregates,
                          inserted_content_relation: RDF::Vocab::ORE.proxyFor,
                          class_name: 'ActiveFedora::Base',
                          through: 'ActiveFedora::Aggregation::Proxy',
                          foreign_key: :target,
                          type_validator: Validators::PCDMObjectValidator

      ##
      # @macro [new] indirectly_contains
      #   @!method $1
      #     @return [ActiveFedora::Associations::ContainerProxy]
      indirectly_contains :member_of_collections,
                          has_member_relation: Vocab::PCDMTerms.memberOf,
                          inserted_content_relation: RDF::Vocab::ORE.proxyFor,
                          class_name: 'ActiveFedora::Base',
                          through: 'ActiveFedora::Aggregation::Proxy',
                          foreign_key: :target,
                          type_validator: Validators::PCDMCollectionValidator
    end

    ##
    # @see ActiveSupport::Concern
    module ClassMethods
      ##
      # @return [Class] the indexer class
      def indexer
        Hydra::PCDM::CollectionIndexer
      end

      ##
      # @return [#validate!] a validator object
      def type_validator
        @type_validator ||= Validators::CompositeValidator.new(
          Validators::PCDMCollectionValidator,
          Validators::PCDMValidator,
          Validators::AncestorValidator
        )
      end
    end

    ##
    # @return [Enumerable<ActiveFedora::Base>]
    def member_of
      return [] if id.nil?
      ActiveFedora::Base.where(Config.indexing_member_ids_key => id)
    end

    ##
    # @return [Enumerable<String>] an ordered list of member ids
    def ordered_member_ids
      ordered_member_proxies.map(&:target_id)
    end

    ##
    # Gives the subset of #members that are PCDM objects
    #
    # @return [Enumerable<PCDM::ObjectBehavior>] an enumerable over the members
    #   that are PCDM objects
    def objects
      members.select(&:pcdm_object?)
    end

    ##
    # Gives a subset of #member_ids, where all elements are PCDM objects.
    # @return [Enumerable<String>] the object ids
    def object_ids
      objects.map(&:id)
    end

    ##
    # Gives a subset of {#ordered_members}, where all elements are PCDM objects.
    #
    # @return [Enumerable<PCDM::ObjectBehavior>]
    def ordered_objects
      ordered_members.to_a.select(&:pcdm_object?)
    end

    ##
    # @return [Enumerable<String>] an ordered list of member ids
    def ordered_object_ids
      ordered_objects.map(&:id)
    end

    ##
    # @return [Enumerable<Hydra::PCDM::CollectionBehavior>] the collections the
    #   object is a member of.
    def in_collections
      member_of.select(&:pcdm_collection?).to_a
    end

    # @return [Enumerable<String>] ids for collections the object is a member of
    def in_collection_ids
      in_collections.map(&:id)
    end

    ##
    # @param [ActiveFedora::Base] potential_ancestor  the resource to check for
    #   ancestorship
    # @return [Boolean] whether the argument is an ancestor of the object
    def ancestor?(potential_ancestor)
      ::Hydra::PCDM::AncestorChecker.former_is_ancestor_of_latter?(potential_ancestor, self)
    end

    ##
    # @return [Enumerable<PCDM::CollectionBehavior>]
    def collections
      members.select(&:pcdm_collection?)
    end

    ##
    # @return [Enumerable<String>]
    def collection_ids
      members.select(&:pcdm_collection?).map(&:id)
    end

    ##
    # @return [Enumerable<PCDM::CollectionBehavior>]
    def ordered_collections
      ordered_members.to_a.select(&:pcdm_collection?)
    end

    ##
    # @return [Enumerable<String>]
    def ordered_collection_ids
      ordered_collections.map(&:id)
    end

    ##
    # @return [Boolean] whether this instance is a PCDM Object.
    def pcdm_object?
      false
    end

    ##
    # @return [Boolean] whether this instance is a PCDM Collection.
    def pcdm_collection?
      true
    end
  end
end
