module Hydra
  module PCDM

    # vocabularies
    autoload :RDFVocabularies,        'hydra/pcdm/vocab/pcdm_terms'
    autoload :EBUCoreVocabularies,    'hydra/pcdm/vocab/ebucore_terms'
    autoload :SweetjplVocabularies,   'hydra/pcdm/vocab/sweetjpl_terms'

    # models
    autoload :Collection,             'hydra/pcdm/models/collection'
    autoload :Object,                 'hydra/pcdm/models/object'
    autoload :File,                   'hydra/pcdm/models/file'

    # behavior concerns
    autoload :CollectionBehavior,     'hydra/pcdm/models/concerns/collection_behavior'
    autoload :ObjectBehavior,         'hydra/pcdm/models/concerns/object_behavior'

    def self.collection? collection
      return false unless collection.respond_to? :type
      collection.type.include? RDFVocabularies::PCDMTerms.Collection
    end

    def self.object? object
      return false unless object.respond_to? :type
      object.type.include? RDFVocabularies::PCDMTerms.Object
    end

    def self.file? file
      return false unless file.respond_to? :type
      file.type.include? RDFVocabularies::PCDMTerms.File
    end

  end
end
