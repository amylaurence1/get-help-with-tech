require 'rails_helper'

describe Support::UserSummaryListComponent do
  include Rails.application.routes.url_helpers

  let(:responsible_body) { create(:local_authority) }
  subject(:result) { render_inline(described_class.new(user: user)) }

  let(:user) do
    build(:school_user, telephone: '12345', responsible_body: responsible_body)
  end

  it 'displays the email address' do
    expect(value_for_row(result, 'Email address').text).to include(user.email_address)
  end

  it 'displays the telephone' do
    expect(value_for_row(result, 'Telephone').text).to include('12345')
  end

  context 'for a user who cannot order devices' do
    let(:user) do
      build(:school_user, telephone: '12345', orders_devices: false)
    end

    it 'displays the user as unable to order devices' do
      expect(value_for_row(result, 'Can order devices?').text).to include('No')
    end
  end

  context 'for a user who orders devices but has not seen the privacy notice' do
    let(:user) do
      build(:school_user, telephone: '12345', orders_devices: true, privacy_notice_seen_at: nil)
    end

    it 'displays the user as able to order devices once they sign in' do
      expect(value_for_row(result, 'Can order devices?').text).to include('No, will get a TechSource account once they sign in')
    end
  end

  context 'for a user who orders devices, has seen the privacy notice but has no TechSource account yet' do
    let(:user) do
      build(:school_user,
            telephone: '12345',
            orders_devices: true,
            privacy_notice_seen_at: 5.days.ago,
            techsource_account_confirmed_at: nil)
    end

    it "displays the user as able to order devices once it's confirmed that they have a TechSource account" do
      expect(value_for_row(result, 'Can order devices?').text).to include('No, waiting for TechSource account')
    end
  end

  context 'for a user who orders devices, has seen the privacy notice and has a TechSource account yet' do
    let(:user) do
      build(:school_user,
            telephone: '12345',
            orders_devices: true,
            privacy_notice_seen_at: 5.days.ago,
            techsource_account_confirmed_at: 4.days.ago)
    end

    it 'displays the user as able to order devices' do
      expect(value_for_row(result, 'Can order devices?').text).to include('Yes')
    end
  end

  it 'renders links to the responsible body support page' do
    expect(result.to_html).to include(support_responsible_body_path(user.responsible_body))
  end

  it 'renders links to the school support pages' do
    user.schools.each do |school|
      expect(result.to_html).to include(support_school_path(urn: school.urn))
    end
  end
end
