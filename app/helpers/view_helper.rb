module ViewHelper
  def ghwt_contact_mailto(subject: nil, label: 'COVID.TECHNOLOGY@education.gov.uk')
    mail_to_url = [
      'mailto:COVID.TECHNOLOGY@education.gov.uk',
      (subject.present? ? "subject=#{ERB::Util.url_encode(subject)}" : nil),
    ].compact.join('?')

    govuk_link_to label, mail_to_url
  end

  def govuk_button_link_to(body, url, html_options = {})
    html_options[:class] = prepend_css_class('govuk-button', html_options[:class])

    link_to(body, url, role: 'button', class: html_options[:class], 'data-module': 'govuk-button', draggable: false)
  end

  def govuk_start_button_link_to(body, url, html_options = {})
    options = {
      class: prepend_css_class('govuk-button govuk-button--start', html_options[:class]),
      role: 'button',
      data: { module: 'govuk-button' },
      draggable: false,
    }.merge(html_options.except(:class))

    link_to(url, options) do
      raw(%(#{body}
        <svg class="govuk-button__start-icon" xmlns="http://www.w3.org/2000/svg" width="17.5" height="19" viewBox="0 0 33 40" aria-hidden="true" focusable="false">
          <path fill="currentColor" d="M0 0h13l20 20-20 20H0l20-20z" />
        </svg>))
    end
  end

  def title_with_error_prefix(title, error)
    "#{t('page_titles.error_prefix') if error}#{title}"
  end

  def link_to_devices_guidance_subpage(body, slug, html_options = {})
    govuk_link_to body, devices_guidance_subpage_path(subpage_slug: slug), html_options
  end

  def breadcrumbs(items)
    breadcrumbs = items.map { |k, _v| k.is_a?(Hash) ? k : { k => '' } }.inject(:merge)
    render GovukComponent::Breadcrumbs.new(breadcrumbs: breadcrumbs)
  end

  def school_breadcrumbs(items:, user:, school:)
    render School::SchoolBreadcrumbsComponent.new(items: items, user: user, school: school)
  end

  def sortable_extra_mobile_data_requests_table_header(title, value = title, opts = params)
    if opts[:sort] == value.to_s
      if opts[:dir] == 'd'
        suffix = '▲'
        dir = 'a'
      else
        suffix = '▼'
        dir = 'd'
      end
      safe_join([govuk_link_to(title, mno_extra_mobile_data_requests_path(sort: value, dir: dir)), suffix], ' ')
    else
      govuk_link_to(title, mno_extra_mobile_data_requests_path(sort: value))
    end
  end

  def participation_description(mobile_network)
    [
      mobile_network.translated_enum_value(:participation_in_pilot),
      # TODO: uncomment this when we've added the supports_payg field
      # mobile_network.supports_payg? ? '' : 'Does not support Pay-as-you-go customers.'
    ].join('. ')
  end

  def mobile_network_options(mobile_networks)
    mobile_networks.map do |network|
      OpenStruct.new(
        id: network.id,
        label: network.brand,
        description: participation_description(network),
      )
    end
  end

  def humanized_seconds(seconds)
    ActiveSupport::Duration.build(seconds).inspect
  end

  def humanized_token_lifetime
    humanized_seconds(Settings.sign_in_token_ttl_seconds)
  end

  def who_will_order_devices_options(show_recommendation: true)
    [
      OpenStruct.new(
        id: 'school',
        label: "Most schools and colleges will place their own orders#{' (recommended)' if show_recommendation}",
        description: 'We’ll need contact details for each school or college',
      ),
      OpenStruct.new(
        id: 'responsible_body',
        label: 'Most orders will be placed centrally',
        description: 'You’ll need to place orders for schools and colleges and give technical information for any that want to order Chromebooks',
      ),
    ]
  end

  def change_who_will_order_devices_options
    scope = 'page_titles.change_who_will_order_edit'
    [
      OpenStruct.new(
        id: 'school',
        label: t('school', scope: scope),
      ),
      OpenStruct.new(
        id: 'responsible_body',
        label: t('responsible_body', scope: scope),
      ),
    ]
  end

  def can_user_order_devices_options
    scope = 'page_titles.invite_school_user'
    [
      OpenStruct.new(
        value: '1',
        label: t('can_order_devices', scope: scope),
      ),
      OpenStruct.new(
        value: '0',
        label: t('cannot_order_devices', scope: scope),
      ),
    ]
  end

  def what_to_order_allocation_list(allocations:)
    allocations.map { |alloc|
      "#{alloc.available_devices_count} #{alloc.device_type_name.pluralize(alloc.available_devices_count)}"
    }.join(' and ')
  end

  def what_to_order_availability(school:)
    suffix = (school.can_order_for_specific_circumstances? ? ' for specific circumstances' : nil)

    if school.has_devices_available_to_order?
      string = what_to_order_allocation_list(allocations: school.device_allocations)

      "Order #{string}#{suffix}"
    else
      'All devices ordered'
    end
  end

  def what_to_order_state_list(allocations:)
    allocations.map { |alloc|
      "#{alloc.devices_ordered} #{alloc.device_type_name.pluralize(alloc.devices_ordered)}"
    }.join(' and ')
  end

  def what_to_order_state(school:)
    string = what_to_order_state_list(allocations: school.device_allocations)

    "You’ve ordered #{string}"
  end

  def centrally_managing_count_or_all_schools(responsible_body:)
    schools = responsible_body.schools.gias_status_open
    if responsible_body.is_ordering_for_all_schools?
      'all'
    else
      "#{schools.that_are_centrally_managed.count} of #{schools.count}"
    end
  end

  def link_to_ed_settings_form
    govuk_link_to 'DfE educational settings status form', 'https://form.education.gov.uk/service/educational-setting-status'
  end

private

  def prepend_css_class(css_class, current_class)
    if current_class
      current_class.prepend("#{css_class} ")
    else
      css_class
    end
  end
end
