# frozen_string_literal: true

class MyModel
  include LazyLazer
end

# TODO: have test case for calling a non-required method without a default

RSpec.describe LazyLazer do
  it 'has a version number' do
    expect(LazyLazer::VERSION).not_to be nil
  end

  describe '.properties' do
    it 'returns a hash' do
      expect(MyModel.properties).to eq({})
    end
  end

  describe '.property' do
    it 'adds the property to the property hash' do
      MyModel.property(:test_property)
      expect(MyModel.properties).to include(:test_property)
    end

    it 'returns the name of the created property' do
      expect(MyModel.property(:test_property)).to eq(:test_property)
    end

    it 'coerces the provided property to a symbol' do
      expect(MyModel.property('test_property')).to eq(:test_property)
    end

    it 'creates the appropriate reader method on the class' do
      MyModel.property(:test_property)
      expect(MyModel).to be_method_defined(:test_property)
    end
  end

  describe '#initialize' do
    it 'accepts a Hash of attributes' do
      expect { MyModel.new(hello: :world) }.not_to raise_error
    end

    it 'accepts no arguments' do
      expect { MyModel.new }.not_to raise_error
    end

    it 'raises an error if a required attribute is missing' do
      MyModel.property(:test_property, required: true)
      expect { MyModel.new(hello: 'world') }
        .to raise_error(LazyLazer::RequiredAttribute, 'test_property')
    end
  end

  describe '#to_h' do
    it 'returns a hash'
    it 'lazy loads attributes if it needs to'
  end

  describe '#fully_loaded?' do
    it 'is false on initialization' do
      model = MyModel.new
      expect(model).not_to be_fully_loaded
    end
  end

  describe '#fully_loaded=' do
    it 'makes #fully_loaded? return the new value' do
      model = MyModel.new
      model.send('fully_loaded=', true)
      expect(model).to be_fully_loaded
    end
  end

  describe '#reload' do
    it 'exists in the base implementation' do
      model = MyModel.new
      expect(model).to respond_to(:reload)
    end
  end

  describe '#read_attribute' do
    context 'when a single-key source mapping is present' do
      it 'performs single key mappings on the model (using :from)' do
        MyModel.property(:test_property, from: :source)
        model = MyModel.new(source: 'test value')
        expect(model.read_attribute(:test_property)).to eq('test value')
      end
    end

    context 'when a multi-key source mapping is present' do
      it 'performs multiple-key mappings on the model (using :from)' do
        MyModel.property(:test_property, from: %i[source_one source_two])
        model = MyModel.new(source_one: 'test value')
        expect(model.read_attribute(:test_property)).to eq('test value')
      end

      it 'searches for the appropriate source key from left to right' do
        MyModel.property(:test_property, from: %i[source_two source_one source_three])
        model = MyModel.new(source_one: 1, source_two: 2, source_three: 3)
        expect(model.read_attribute(:test_property)).to eq(2)
      end
    end

    context 'when a :with transformation is provided for a key' do
      context 'when :with is a Proc' do
        it 'calls the Proc with the value of the key'
        it 'calls the Proc in the context of the model'
        context 'when a value is not found but a default is provided' do
          it 'calls the Proc with the value of the default'
        end
      end

      context 'when :with is a Symbol' do
        it 'calls the appropriate method on the returned value'
        context 'when a value is not found but a default is provided' do
          it 'calls the method on the value of the default'
        end
      end
    end
  end

  describe '#assign_attributes' do
    it 'merges the attributes into the model'
  end
end
