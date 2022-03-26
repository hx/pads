# frozen_string_literal: true

module Pads
  describe PadGroup do
    let(:a) { Pad.new }
    let(:b) { Pad.new }
    let(:c) { Pad.new }

    describe '#insert' do
      it 'inserts things into its members' do
        subject.insert 0, a
        subject.insert 1, c
        expect { subject.insert 1, b }.to change { subject.members }.to [a, b, c]
      end
    end

    describe '#delete_at' do
      it 'removes and returns the member at the given index' do
        subject.insert 0, a
        subject.insert 1, c
        expect {
          expect(subject.delete_at(1)).to be c
        }.to change { subject.members }.to [a]
      end
    end

    describe '#batch' do
      let(:observer) { double }

      it 'only notifies observers once' do
        expect(observer).to receive(:update).once.with subject
        subject.add_observer observer
        subject.batch do
          subject.insert 0, a
          subject.insert 1, b
          subject.delete_at 0
        end
        expect(subject.members).to eq [b]
      end
    end

    describe '#==' do
      it 'is only true for the same object' do
        expect(subject).not_to eq described_class.new
        expect(subject).to eq subject
      end
    end
  end
end
