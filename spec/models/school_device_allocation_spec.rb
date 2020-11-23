require 'rails_helper'

RSpec.describe SchoolDeviceAllocation, type: :model do
  it { is_expected.to be_versioned }

  describe '#cap_implied_by_order_state' do
    subject(:allocation) { described_class.new(allocation: 27, cap: nil, devices_ordered: 13) }

    context 'given cannot_order' do
      it 'returns the value of devices_ordered' do
        expect(allocation.cap_implied_by_order_state(order_state: 'cannot_order')).to eq(13)
      end
    end

    context 'given can_order' do
      it 'returns the value of allocation' do
        expect(allocation.cap_implied_by_order_state(order_state: 'can_order')).to eq(27)
      end
    end

    context 'given can_order_for_specific_circumstances' do
      it 'returns the given cap' do
        expect(allocation.cap_implied_by_order_state(order_state: 'can_order_for_specific_circumstances', given_cap: 17)).to eq(17)
      end
    end
  end

  describe 'validations' do
    let(:school) { build(:school) }

    context 'cap exceeds allocation' do
      subject(:allocation) { described_class.new(cap: 11, allocation: 10, school: school) }

      it 'fails validation' do
        expect(allocation.valid?).to be_falsey
        expect(allocation.errors).to have_key(:cap)
        expect(allocation.errors[:cap]).to include('can’t be greater than allocation')
      end
    end

    context 'cap equals allocation' do
      subject(:allocation) { described_class.new(cap: 10, allocation: 10, school: school) }

      it 'passes validation' do
        expect(allocation.valid?).to be_truthy
      end
    end

    context 'cap less than devices_ordered' do
      subject(:allocation) do
        described_class.new(cap: 9,
                            devices_ordered: 10,
                            allocation: 100,
                            school: school)
      end

      it 'passes validation' do
        expect(allocation.valid?).to be_truthy
      end
    end

    context 'cap equals devices_ordered' do
      subject(:allocation) do
        described_class.new(cap: 10,
                            devices_ordered: 10,
                            allocation: 100,
                            school: school)
      end

      it 'passes validation' do
        expect(allocation.valid?).to be_truthy
      end
    end
  end

  describe '#available_devices_count' do
    subject(:allocation) { described_class.new(cap: 100, devices_ordered: 200) }

    context 'when negative' do
      it 'returns zero' do
        expect(allocation.available_devices_count).to be_zero
      end
    end
  end

  context 'when in a virtual pool', with_feature_flags: { virtual_caps: 'active' } do
    let(:responsible_body) { create(:trust, :manages_centrally) }
    let(:school) { create(:school, :with_preorder_information, :in_lockdown, responsible_body: responsible_body) }

    subject(:allocation) { described_class.create!(device_type: 'std_device', cap: 100, devices_ordered: 87, allocation: 120, school: school) }

    before do
      allocation
      school.preorder_information.responsible_body_will_order_devices!
      responsible_body.add_school_to_virtual_cap_pools!(school)
      responsible_body.std_device_pool.update!(allocation: 300, cap: 256, devices_ordered: 145)
      allocation.reload
    end

    it ':allocation refers to the pool allocation instead of local version' do
      expect(allocation.allocation).to eq(300)
      expect(allocation.raw_allocation).to eq(120)
    end

    it ':cap refers to the pool cap instead of local version' do
      expect(allocation.cap).to eq(256)
      expect(allocation.raw_cap).to eq(100)
    end

    it ':devices_ordered refers to the pool devices_ordered instead of the local version' do
      expect(allocation.devices_ordered).to eq(145)
      expect(allocation.raw_devices_ordered).to eq(87)
    end

    it 'propagates changes up to the pool' do
      allocation.update!(allocation: 400, cap: 300, devices_ordered: 200)
      responsible_body.std_device_pool.reload
      expect(responsible_body.std_device_pool.allocation).to eq(400)
      expect(responsible_body.std_device_pool.cap).to eq(300)
      expect(responsible_body.std_device_pool.devices_ordered).to eq(200)
    end
  end
end
