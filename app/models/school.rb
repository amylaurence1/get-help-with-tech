class School < ApplicationRecord
  belongs_to :responsible_body
  has_many   :device_allocations, class_name: 'SchoolDeviceAllocation'

  has_many :contacts, class_name: 'SchoolContact', inverse_of: :school
  has_one :preorder_information

  validates :urn, presence: true, format: { with: /\A\d{6}\z/ }
  validates :name, presence: true

  enum phase: {
    primary: 'primary',
    secondary: 'secondary',
    all_through: 'all_through',
    sixteen_plus: 'sixteen_plus',
    nursery: 'nursery',
    phase_not_applicable: 'phase_not_applicable',
  }

  enum establishment_type: {
    academy: 'academy',
    free: 'free',
    local_authority: 'local_authority',
    special: 'special',
    other_type: 'other_type',
  }

  def allocation_for_type!(device_type)
    device_allocations.find_by_device_type!(device_type)
  end

  # TODO: update this method as preorder_information gets more fields
  # as per the prototype at
  # https://github.com/DFE-Digital/increasing-internet-access-prototype/blob/master/app/views/responsible-body/devices/school/_status-tag.html
  def preorder_status_or_default
    if preorder_information.present?
      preorder_information.status || preorder_information.infer_status
    elsif responsible_body.who_will_order_devices == 'responsible_body'
      'needs_info'
    else
      'needs_contact'
    end
  end
end
