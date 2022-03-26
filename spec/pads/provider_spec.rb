# frozen_string_literal: true

module Pads
  describe Provider do
    let(:client) { TestClient.new }

    subject { described_class.new client }

    it 'syncs new pads to its client' do
      expect { subject.push Pad.new }.to change { client.pads.count }.by 1
    end

    it 'sync pad changes to its client' do
      pad = Pad.new
      subject.push pad
      expect(client).to receive(:call) do |klass, message, headers|
        expect(klass).to be :set_pad_title
        expect(message.body).to eq 'foobar'.to_json
        expect(headers).to eq pad_id: client.pads.first.pad_id
      end
      pad.view.title = 'foobar'
    end

    it 'syncs pad destruction to its clients' do
      pad = Pad.new
      subject.push pad
      expect { pad.parent.delete_at 0 }.to change { client.pads.count }.by -1
    end

    it 'syncs new pads in subgroups to its client' do
      group = PadGroup.new
      expect { subject.push group }.not_to change { client.pads.count }
      expect { group.push Pad.new }.to change { client.pads.count }.by 1
    end

    it 'syncs pad destruction in subgroups to its client' do
      group = PadGroup.new
      subject.push group
      pad = Pad.new
      group.push pad
      expect { group.delete_at 0 }.to change { client.pads.count }.by -1
    end

    it 'syncs new pads in the correct order' do
      subject.push Pad.new
      expect { subject.push Pad.new }.not_to change { client.pads.first.pad_id }
      expect(client.pads.length).to be 2
    end
  end
end
