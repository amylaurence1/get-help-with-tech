class School < ApplicationRecord
  belongs_to :responsible_body
  has_many   :device_allocations, class_name: 'SchoolDeviceAllocation'
  has_one    :std_device_allocation, -> { where device_type: 'std_device' }, class_name: 'SchoolDeviceAllocation'
  has_one    :coms_device_allocation, -> { where device_type: 'coms_device' }, class_name: 'SchoolDeviceAllocation'

  has_many :contacts, class_name: 'SchoolContact', inverse_of: :school
  has_many :user_schools
  has_many :users, through: :user_schools
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
  }, _suffix: true

  enum order_state: {
    cannot_order: 'cannot_order',
    can_order_for_specific_circumstances: 'can_order_for_specific_circumstances',
    can_order: 'can_order',
  }

  def self.that_will_order_devices
    joins(:preorder_information).merge(PreorderInformation.school_will_order_devices)
  end

  def self.that_are_centrally_managed
    joins(:preorder_information).merge(PreorderInformation.responsible_body_will_order_devices)
  end

  def self.that_can_order_now
    where(order_state: %w[can_order_for_specific_circumstances can_order])
  end

  def who_will_order_devices
    preorder_information&.who_will_order_devices || responsible_body.who_will_order_devices
  end

  def active_responsible_users
    case who_will_order_devices
    when 'school'
      users.signed_in_at_least_once
    else
      responsible_body.users.signed_in_at_least_once
    end
  end

  def allocation_for_type!(device_type)
    device_allocations.find_by_device_type!(device_type)
  end

  def can_order_devices_right_now?
    is_eligible_to_order? && has_devices_available_to_order?
  end

  def all_devices_ordered?
    is_eligible_to_order? && !has_devices_available_to_order?
  end

  def has_std_device_allocation?
    std_device_allocation&.allocation.to_i.positive?
  end

  def type_label
    if special_establishment_type?
      'Special school'
    elsif !phase_not_applicable?
      "#{phase.humanize.upcase_first} school"
    else
      ''
    end
  end

  def headteacher_contact
    contacts.find_by(role: :headteacher)
  end

  def current_contact
    preorder_information&.school_contact
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

  def next_school_in_responsible_body_when_sorted_by_name_ascending
    responsible_body.next_school_sorted_ascending_by_name(self)
  end

  def invite_school_contact
    if preorder_information.present?
      preorder_information.invite_school_contact!
    else
      false
    end
  end

private

  def is_eligible_to_order?
    can_order? || can_order_for_specific_circumstances?
  end

  def has_devices_available_to_order?
    std_device_allocation&.has_devices_available_to_order?
  end
end
