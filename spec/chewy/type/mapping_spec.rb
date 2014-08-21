require 'spec_helper'

describe Chewy::Type::Mapping do
  let(:product) { ProductsIndex::Product }

  before do
    stub_index(:products) do
      define_type :product do
        root do
          field :name, 'surname'
          field :title, type: 'string' do
            field :subfield1
          end
          field 'price', type: 'float' do
            field :subfield2
          end
        end
      end
    end
  end

  describe '.field' do
    specify { product.root_object.nested.keys.should =~ [:name, :surname, :title, :price] }
    specify { product.root_object.nested.values.should satisfy { |v| v.all? { |f| f.is_a? Chewy::Fields::Base } } }

    specify { product.root_object.nested[:title].nested.keys.should == [:subfield1] }
    specify { product.root_object.nested[:title].nested[:subfield1].should be_a Chewy::Fields::Base }

    specify { product.root_object.nested[:price].nested.keys.should == [:subfield2] }
    specify { product.root_object.nested[:price].nested[:subfield2].should be_a Chewy::Fields::Base }
  end

  describe '.mappings_hash' do
    specify { Class.new(Chewy::Type::Base).mappings_hash.should == {} }
    specify { product.mappings_hash.should == product.root_object.mappings_hash }

    context 'parent-child relationship' do
      before do
        stub_index(:products) do
          define_type :product do
            root parent: 'project', parent_id: -> { project_id } do
              field :name, 'surname'
            end
          end
        end
      end

      specify { product.mappings_hash[:product][:_parent].should == { type: 'project' } }
    end
  end

  context "no root element call" do
    before do
      stub_index(:products) do
        define_type :product do
          field :title, type: 'string' do
            field :subfield1
          end
        end
      end
    end

    specify { product.root_object.nested[:title].nested.keys.should == [:subfield1] }
    specify { product.root_object.nested[:title].nested[:subfield1].should be_a Chewy::Fields::Base }
  end
end
