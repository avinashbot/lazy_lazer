# frozen_string_literal: true

# TODO: have test case for calling a non-required method without a default

RSpec.describe LazyLazer do
  let(:model_class) { Class.new { include LazyLazer } }

  it 'has a version number' do
    expect(LazyLazer::VERSION).not_to be nil
  end

  describe '.properties' do
    it 'returns a hash' do
      expect(model_class.properties).to eq({})
    end
  end

  describe '.property' do
    it 'adds the property to the property hash' do
      model_class.property(:test_property)
      expect(model_class.properties).to include(:test_property)
    end

    it 'returns the name of the created property' do
      expect(model_class.property(:test_property)).to eq(:test_property)
    end

    it 'coerces the provided property to a symbol' do
      expect(model_class.property('test_property')).to eq(:test_property)
    end

    it 'creates the appropriate reader method on the class' do
      model_class.property(:test_property)
      expect(model_class).to be_method_defined(:test_property)
    end
  end

  describe '#initialize' do
    it 'accepts a Hash of attributes' do
      expect { model_class.new(hello: :world) }.not_to raise_error
    end

    it 'accepts no arguments' do
      expect { model_class.new }.not_to raise_error
    end

    it 'raises an error if a required attribute is missing' do
      model_class.property(:test_property, required: true)
      expect { model_class.new(hello: 'world') }
        .to raise_error(LazyLazer::RequiredAttribute, /test_property/)
    end
  end

  describe '#to_h' do
    it 'returns a hash'
    it 'lazy loads attributes if it needs to'
  end

  describe '#fully_loaded?' do
    it 'is false on initialization' do
      model = model_class.new
      expect(model).not_to be_fully_loaded
    end
  end

  describe '#fully_loaded=' do
    it 'makes #fully_loaded? return the new value' do
      model = model_class.new
      model.send('fully_loaded=', true)
      expect(model).to be_fully_loaded
    end
  end

  describe '#reload' do
    it 'exists in the base implementation' do
      model = model_class.new
      expect(model).to respond_to(:reload)
    end
  end

  describe '#read_attribute' do
    context 'when a single-key source mapping is present' do
      it 'performs single key mappings on the model (using :from)' do
        model_class.property(:test_property, from: :source)
        model = model_class.new(source: 'test value')
        expect(model.read_attribute(:test_property)).to eq('test value')
      end
    end

    context 'when a multi-key source mapping is present' do
      it 'performs multiple-key mappings on the model (using :from)' do
        model_class.property(:test_property, from: %i[source_one source_two])
        model = model_class.new(source_one: 'test value')
        expect(model.read_attribute(:test_property)).to eq('test value')
      end

      it 'searches for the appropriate source key from left to right' do
        model_class.property(:test_property, from: %i[source_two source_one source_three])
        model = model_class.new(source_one: 1, source_two: 2, source_three: 3)
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
