# frozen_string_literal: true

module Pads
  describe TestClient do
    it 'can swap pads' do
      pads = 7.times.map { subject.create_pad }
      subject.swap_pads [pads[1], pads[2]], [pads[4], pads[5]]
      expect(subject.pads).to eq [0, 4, 5, 3, 1, 2, 6].map { |i| pads[i] }
    end

    it 'can create pads out of order' do
      pads = []
      pads << subject.create_pad
      pads << subject.create_pad
      pads << subject.create_pad(after: pads.first)
      pads << subject.create_pad(before: pads.first)
      pads << subject.create_pad(before: pads.last)
      pads << subject.create_pad(after: pads.last)

      expect(subject.pads).to eq [4, 5, 3, 0, 2, 1].map { |i| pads[i] }
    end
  end
end
