module Hydra::PCDM
  ##
  # Implements behavior for PCDM objects.
  #
  # The behavior is summarized as:
  #   1) Hydra::PCDM::Object can aggregate (pcdm:hasMember) Hydra::PCDM::Object
  #   2) Hydra::PCDM::Object can aggregate (ore:aggregates) Hydra::PCDM::Object  (Object related to the Object)
  #   3) Hydra::PCDM::Object can contain (pcdm:hasFile) Hydra::PCDM::File
  #   4) Hydra::PCDM::Object can contain (pcdm:hasRelatedFile) Hydra::PCDM::File
  #   5) Hydra::PCDM::Object can NOT aggregate Hydra::PCDM::Collection
  #   6) Hydra::PCDM::Object can NOT aggregate non-PCDM object
  #   7) Hydra::PCDM::Object can have descriptive metadata
  #   8) Hydra::PCDM::Object can have access metadata
  #
  # @example defining an object class and creating an object
  #   class Book < ActiveFedora::Base
  #     include Hydra::PCDM::ObjectBehavior
  #   end
  #
  #   my_book = Book.create
  #   # #<Book id: "71/3f/07/e0/713f07e0-9d5c-493a-bdb9-7fbfe2160028", head: [], tail: []>
  #
  #   my_book.pcdm_object?     # => true
  #   my_book.pcdm_collection? # => false
  #
  # @example adding a members to an object
  #   class Page < ActiveFedora::Base
  #     include Hydra::PCDM::ObjectBehavior
  #   end
  #
  #   my_book = Book.create
  #   a_page  = Page.create
  #
  #   my_book.members << a_page
  #   my_book.members # => [a_page]
  #
  # @see PcdmBehavior for details about the base behavior required by
  #   this module.
  module ObjectBehavior
    extend ActiveSupport::Concern

    included do
      include Hydra::PCDM::PcdmBehavior
      type Vocab::PCDMTerms.Object

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
      # @macro [new] directly_contains
      #   @!method $1
      #     @return [ActiveFedora::Associations::ContainerProxy]
      directly_contains :files, has_member_relation: Vocab::PCDMTerms.hasFile,
                                class_name: 'Hydra::PCDM::File'

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
        Hydra::PCDM::ObjectIndexer
      end

      ##
      # @return [#validate!] a validator object
      def type_validator
        @type_validator ||= Validators::CompositeValidator.new(
          Validators::PCDMObjectValidator,
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
    # @return [Boolean] whether this instance is a PCDM Object.
    def pcdm_object?
      true
    end

    ##
    # @return [Boolean] whether this instance is a PCDM Collection.
    def pcdm_collection?
      false
    end

    ##
    # @return [Enumerable<Hydra::PCDM::ObjectBehavior>]
    def in_objects
      member_of.select(&:pcdm_object?).to_a
    end

    ##
    # @return [Enumerable<String>]
    def member_of_collection_ids
      member_of_collections.map(&:id)
    end

    ##
    # Gives directly contained files that have the requested RDF Type
    #
    # @param [RDF::URI] uri for the desired Type
    # @return [Enumerable<ActiveFedora::File>]
    #
    # @example
    #   filter_files_by_type(::RDF::URI("http://pcdm.org/ExtractedText"))
    def filter_files_by_type(uri)
      files.reject do |file|
        !file.metadata_node.type.include?(uri)
      end
    end

    ##
    # Finds or Initializes directly contained file with the requested RDF Type
    #
    # @param [RDF::URI] uri for the desired Type
    # @return [ActiveFedora::File]
    #
    # @example
    #   file_of_type(::RDF::URI("http://pcdm.org/ExtractedText"))
    def file_of_type(uri)
      matching_files = filter_files_by_type(uri)
      return matching_files.first unless matching_files.empty?
      Hydra::PCDM::AddTypeToFile.call(files.build, uri)
    end
  end
end
