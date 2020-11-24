module Computacenter
  module CapChangeNotifier
    def notify_computacenter_of_cap_changes?
      Settings.computacenter.outgoing_api.endpoint.present?
    end

    def notify_computacenter_by_email(school, device_type, new_cap_value)
      mailer = ComputacenterMailer.with(school: school, new_cap_value: new_cap_value)

      if device_type == 'std_device'
        mailer.notify_of_devices_cap_change.deliver_later
      else
        mailer.notify_of_comms_cap_change.deliver_later
      end
    end

    def update_cap_on_computacenter!(allocation_ids)
      ids = Array(allocation_ids)
      api_request = Computacenter::OutgoingAPI::CapUpdateRequest.new(allocation_ids: ids)
      response = api_request.post!

      SchoolDeviceAllocation.where(id: ids).find_each do |allocation|
        allocation.update!(
          cap_update_request_timestamp: api_request.timestamp,
          cap_update_request_payload_id: api_request.payload_id,
        )
        allocation.cap_update_calls << CapUpdateCall.new(request_body: api_request.body, response_body: response.body)
      end
      response
    end
  end
end
