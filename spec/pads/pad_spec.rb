# frozen_string_literal: true

module Pads
  describe Pad do
    describe '#==' do
      it 'is only true for the same object' do
        expect(subject).not_to eq described_class.new
        expect(subject).to eq subject
      end
    end

    it 'is not considered equivalent in logical array operations' do
      arr = [subject]
      expect { arr -= [described_class.new] }.not_to change { arr }
    end
  end
end
