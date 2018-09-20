require 'spec_helper'

describe Hydra::PCDM::PcdmBehavior do
  before do
    class ParentModel < ActiveFedora::Base
      def self.type_validator
        Hydra::PCDM::Validators::PCDMValidator
      end
    end
    class MyModel < ParentModel
      include Hydra::PCDM::PcdmBehavior

      def pcdm_object?
        true
      end
    end
  end

  after do
    Object.send(:remove_const, :MyModel)
    Object.send(:remove_const, :ParentModel)
  end

  describe '#ordered_member_ids' do
    subject(:my_model) { MyModel.new }
    it 'retrieves the IDs of member resources' do
      o = MyModel.new
      subject.ordered_members << o

      expect(my_model.ordered_member_ids).to eq [o.id]
    end
  end

  describe '#member_of_collection_ids' do
    subject(:my_model) do
      object = MyModel.new
      object.member_of_collections = [collection1, collection2]
      object.save
      object
    end
    let(:collection1) { Hydra::PCDM::Collection.create }
    let(:collection2) { Hydra::PCDM::Collection.create }

    it 'retrieves the IDs of parent collections' do
      expect(my_model.member_of_collection_ids).to match_array [collection1.id, collection2.id]
    end
  end
end
