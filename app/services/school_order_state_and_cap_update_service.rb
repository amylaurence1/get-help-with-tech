class SchoolOrderStateAndCapUpdateService
  include Computacenter::CapChangeNotifier

  attr_accessor :school, :order_state, :caps
  attr_reader :disable_user_notifications

  def initialize(school:, order_state:, std_device_cap: nil, coms_device_cap: nil)
    @school = school
    @order_state = order_state
    @caps = [
      { device_type: 'std_device', cap: std_device_cap },
      { device_type: 'coms_device', cap: coms_device_cap },
    ]
    @disable_user_notifications = false
  end

  def call
    update!
  end

  def update!
    update_order_state!(order_state)

    caps.each do |cap|
      allocation = update_cap!(cap[:device_type], cap[:cap])
      # don't send updates as they will happen when the pool is updated and the caps adjusted
      next if responsible_body_has_virtual_caps_enabled? && allocation.is_in_virtual_cap_pool?

      update_and_notify_computacenter!(allocation)
    end

    # ensure the updates are picked up
    school.reload

    school&.preorder_information&.refresh_status!

    add_school_to_virtual_cap_pool_if_eligible

    # notifying users should only happen after successful completion of the Computacenter
    # cap update, because it's possible for that to fail and the whole thing
    # is rolled back
    notify_school_by_email(school) unless disable_user_notifications
  end

  def disable_user_notifications!
    @disable_user_notifications = true
  end

private

  def responsible_body_has_virtual_caps_enabled?
    school.responsible_body.has_virtual_cap_feature_flags?
  end

  def update_order_state!(order_state)
    school.update!(order_state: order_state)
  end

  def update_cap!(device_type, cap)
    allocation = SchoolDeviceAllocation.find_or_initialize_by(school_id: school.id, device_type: device_type)
    # we only take the cap from the user if they chose specific circumstances
    # for both other states, we need to infer a new cap from the chosen state
    allocation.cap = allocation.cap_implied_by_order_state(order_state: school.order_state, given_cap: cap)
    allocation.save!
    allocation
  end

  def update_and_notify_computacenter!(allocation)
    if school.can_notify_computacenter? && notify_computacenter_of_cap_changes?
      update_cap_on_computacenter!(allocation.id)
      notify_computacenter_by_email(school, allocation.device_type, allocation.cap)
    end
  end

  def add_school_to_virtual_cap_pool_if_eligible
    return unless school&.preorder_information&.responsible_body_will_order_devices?
    return if school.device_allocations.first.is_in_virtual_cap_pool?

    begin
      school.responsible_body.add_school_to_virtual_cap_pools!(school)
    rescue VirtualCapPoolError
      Rails.logger.error("Failed to add school to virtual pool (urn: #{school.urn})")
    end
  end
end
