# frozen_string_literal: true

RSpec.describe LazyLazer do
  let(:model_class) { Class.new { include LazyLazer } }

  describe '.property' do
    it 'returns the created property name' do
      expect(model_class.property(:hello)).to eq(:hello)
    end

    it 'makes the method callable from instances' do
      model_class.property(:hello)
      model = model_class.new(hello: 'world')
      expect(model.hello).to eq('world')
    end

    it 'converts a parameter to a key where the value is true' do
      model_class.property(:hello, :required)
      expect { model_class.new }.to raise_error(LazyLazer::RequiredAttribute, /hello/)
    end
  end

  describe '#initialize' do
    it "sets the model's attributes" do
      model_class.property(:hello)
      model = model_class.new(hello: 'world')
      expect(model.hello).to eq('world')
    end
  end

  describe '#read_attribute' do
    it 'returns the attribute value' do
      model_class.property(:hello)
      model = model_class.new(hello: 'world')
      expect(model.read_attribute(:hello)).to eq('world')
    end

    context "when the attribute doesn't exist" do
      context "if the model isn't fully loaded" do
        it 'calls #reload and returns the new attribute' do
          model_class.property(:hello)
          model = model_class.new
          expect(model).to receive(:lazer_reload).and_return(hello: 'world')
          expect(model.read_attribute(:hello)).to eq('world')
        end

        context "if reload doesn't return the expected attribute" do
          it 'raises a MissingAttribute error' do
            model_class.property(:hello)
            model = model_class.new
            expect(model).to receive(:lazer_reload).and_return(foo: 'bar')
            expect { model.read_attribute(:hello) }
              .to raise_error(LazyLazer::MissingAttribute, /hello/)
          end
        end
      end

      context 'if the model is fully loaded' do
        it 'raises a MissingAttribute error' do
          model_class.property(:hello)
          model = model_class.new
          expect(model).to receive(:fully_loaded?).and_return(true)
          expect { model.read_attribute(:hello) }
            .to raise_error(LazyLazer::MissingAttribute, /hello/)
        end
      end
    end

    context 'when :required is true' do
      it "raises an error when the property isn't supplied" do
        model_class.property(:hello, required: true)
        expect { model_class.new }.to raise_error(LazyLazer::RequiredAttribute, /hello/)
      end

      it "doesn't raise an error when the property is supplied" do
        model_class.property(:hello, required: true)
        expect { model_class.new(hello: 'world') }.not_to raise_error
      end
    end

    context 'when :with is provided' do
      context 'when :with is a Proc' do
        it 'calls the Proc in the context of the block' do
          model_class.property(:return_self, with: ->(_) { self })
          model = model_class.new(return_self: nil)
          expect(model.return_self).to eq(model)
        end
      end

      context 'when :with is a Symbol' do
        it 'calls the method on the value to fetch the new value' do
          model_class.property(:hello, with: :upcase)
          expect(model_class.new(hello: 'world').hello).to eq('WORLD')
        end
      end
    end

    context 'when :default is provided' do
      context 'when :default is a Proc' do
        it 'calls the Proc in the context of the block' do
          model_class.property(:return_self, default: ->() { self })
          model = model_class.new
          expect(model.return_self).to eq(model)
        end
      end

      context "when :default isn't a Proc" do
        it 'returns the default value if the attribute is not provided' do
          model_class.property(:hello, default: 'default world')
          expect(model_class.new(foo: 'bar').hello).to eq('default world')
        end

        it 'returns the provided value if a value is provided' do
          model_class.property(:hello, default: 'default world')
          expect(model_class.new(hello: 'world').hello).to eq('world')
        end

        it 'applies :with transformation on the default value' do
          model_class.property(:hello, default: 'world', with: :upcase)
          expect(model_class.new.hello).to eq('WORLD')
        end
      end
    end

    context 'when :from is provided' do
      it 'uses the source attribute to fetch the value' do
        model_class.property(:hello, from: :foo)
        expect(model_class.new(foo: 'world').hello).to eq('world')
      end

      it 'checks for required using the source attribute' do
        model_class.property(:hello, from: :foo, required: true)
        expect { model_class.new(foo: 'bar') }.not_to raise_error
      end

      it 'checks for default using the source attribute' do
        model_class.property(:hello, from: :foo, default: 'default world')
        expect(model_class.new(hello: 'world').hello).to eq('default world')
        expect(model_class.new(foo: 'bar').hello).to eq('bar')
      end

      it 'applies with transformation using the source attribute' do
        model_class.property(:hello, from: :foo, with: :upcase)
        expect(model_class.new(foo: 'world').hello).to eq('WORLD')
      end
    end
  end

  describe '#[]' do
    it 'calls #read_attribute' do
      model_class.property(:hello)
      model = model_class.new(hello: 'world')
      expect(model).to receive(:read_attribute).with(:hello)
      model[:hello]
    end

    it "returns nil if the attribute can't be found" do
      model_class.property(:hello)
      model = model_class.new
      expect(model[:hello]).to be_nil
    end
  end

  describe '#to_h' do
    it 'returns a Hash' do
      model_class.property(:hello)
      expect(model_class.new(hello: 'world').to_h).to be_a(Hash)
    end

    context 'when :strict is true' do
      it 'coerces uncoerced attributes' do
        called = false
        model_class.property(:hello, with: ->(_) { called = true })
        model_class.new(hello: 1).to_h
        expect(called).to be(true)
      end
    end

    context 'when :strict is false' do
      it 'skips uncoerced attributes' do
        called = false
        model_class.property(:hello, with: ->(_) { called = true })
        model_class.new(hello: 1).to_h(false)
        expect(called).to be(false)
      end
    end
  end

  describe '#reload' do
    it 'calls #lazer_reload' do
      model = model_class.new
      expect(model).to receive(:lazer_reload).and_return({})
      model.reload
    end

    it 'merges the new values into the model' do
      model_class.property(:hello, from: :foo)
      model = model_class.new
      allow(model).to receive(:lazer_reload).and_return(foo: 1)
      expect(model.reload.hello).to eq(1)
    end

    it 'updates the existing values' do
      model_class.property(:hello, from: :foo)
      model = model_class.new(foo: 1)
      allow(model).to receive(:lazer_reload).and_return(foo: 2)
      expect(model.reload.hello).to eq(2)
    end

    it 'returns self' do
      model = model_class.new
      expect(model.reload).to eq(model)
    end
  end

  describe '#write_attribute' do
    it 'updates the attribute directly' do
      model_class.property(:hello, from: :foo, with: :to_i)
      model = model_class.new
      model.write_attribute(:hello, '50')
      expect(model.hello).to eq('50')
    end
  end

  describe '#assign_attributes' do
    it 'calls #write_attribute for each one' do
      model_class.property(:hello)
      model_class.property(:world)
      model = model_class.new(hello: 'world', foo: 'bar')
      expect(model).to receive(:write_attribute).with(:hello, 'new world')
      expect(model).to receive(:write_attribute).with(:foo, 'new bar')
      model.assign_attributes(hello: 'new world', foo: 'new bar')
    end
  end

  describe '#fully_loaded?' do
    it 'is false by default' do
      model = model_class.new
      expect(model.fully_loaded?).to eq(false)
    end
  end

  describe '#fully_loaded!' do
    it 'updates the result of #fully_loaded?' do
      model = model_class.new
      model.send(:fully_loaded!)
      expect(model.fully_loaded?).to eq(true)
    end
  end
end
