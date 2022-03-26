# frozen_string_literal: true

module Pads
  describe Mapper do
    let(:source) { LiveArray.new(%i[a b c]) }
    let(:pads) { Hash.new { |hash, key| hash[key] = Pad.new }.method(:[]) }
    let(:group) { subject.target }

    subject { described_class.new(source, id: :to_s) { |sym| pads[sym] } }

    describe '#initialize' do
      it 'creates a new group with mapping results' do
        expect(group.members).to eq source.map(&pads)
      end
    end

    describe 'observations on the given source' do
      describe 'replacing the entire source' do
        cases = [
          %i[a b],
          %i[c d],
          %i[a b c d e],
          %i[c b a],
          %i[b a d],
          %i[a b d],
          %i[b c]
        ]
        cases.each do |new_syms|
          it "matches new sequence [#{new_syms.map(&:inspect).join ', '}]" do
            expect { source.replace new_syms }.to change { group.members }.to new_syms.map(&pads)
          end
        end
      end

      it 'do not change the group when the source does not change' do
        expect(group).not_to receive(:insert)
        expect(group).not_to receive(:delete_at)
        source[2] = :c
      end
    end
  end
end
