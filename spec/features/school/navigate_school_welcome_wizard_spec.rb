require 'rails_helper'

RSpec.feature 'Navigate school welcome wizard' do
  let(:school) { create(:school, :with_preorder_information, :with_std_device_allocation) }

  before do
    allow(Gsuite).to receive(:is_gsuite_domain?).and_return(true)
  end

  scenario 'step through the wizard as the first user for a school' do
    as_a_new_school_user
    when_i_sign_in_for_the_first_time
    then_i_see_a_welcome_page_for_my_school

    when_i_click_continue
    then_i_see_a_privacy_notice

    when_i_click_continue
    then_i_see_the_allocation_for_my_school

    when_i_click_continue
    then_i_see_the_order_your_own_page

    when_i_click_continue
    then_i_see_the_techsource_account_page

    when_i_click_continue
    then_i_see_the_will_other_order_page

    when_i_choose_yes_and_submit_the_form
    then_i_see_information_about_devices_i_can_order

    when_i_click_continue
    then_im_asked_whether_my_school_will_order_chromebooks

    when_i_choose_yes_and_submit_the_chromebooks_form
    then_i_see_information_about_what_happens_next

    when_i_click_to_finish_and_go_to_homepage
    then_i_see_the_school_home_page
  end

  scenario 'step through wizard as subsequent user when the chromebooks question has been answered yes/no' do
    as_a_subsequent_school_user
    when_the_chromebooks_question_has_already_been_answered
    when_i_sign_in_for_the_first_time
    then_i_see_a_welcome_page_for_my_school

    when_i_click_continue
    then_i_see_a_privacy_notice

    when_i_click_continue
    then_i_see_the_allocation_for_my_school

    when_i_click_continue
    then_i_see_the_order_your_own_page

    when_i_click_continue
    then_i_see_information_about_devices_i_can_order

    when_i_click_continue
    then_i_see_information_about_what_happens_next

    when_i_click_to_finish_and_go_to_homepage
    then_i_see_the_school_home_page
  end

  scenario 'step through wizard as subsequent user when the chromebooks question has not been answered yes/no' do
    as_a_subsequent_school_user
    when_i_sign_in_for_the_first_time
    then_i_see_a_welcome_page_for_my_school

    when_i_click_continue
    then_i_see_a_privacy_notice

    when_i_click_continue
    then_i_see_the_allocation_for_my_school

    when_i_click_continue
    then_i_see_the_order_your_own_page

    when_i_click_continue
    then_i_see_information_about_devices_i_can_order

    when_i_click_continue
    then_im_asked_whether_my_school_will_order_chromebooks

    when_i_choose_no_and_submit_the_chromebooks_form
    then_i_see_information_about_what_happens_next

    when_i_click_to_finish_and_go_to_homepage
    then_i_see_the_school_home_page
  end

  scenario 'the wizard resumes where left off' do
    as_a_new_school_user
    when_i_sign_in_for_the_first_time
    then_i_see_a_welcome_page_for_my_school

    when_i_click_continue
    then_i_see_a_privacy_notice

    when_i_sign_out
    and_then_sign_in_again
    then_i_see_a_privacy_notice
  end

  def as_a_new_school_user
    @user = create(:school_user, :new_visitor, :has_not_seen_privacy_notice, school: school, orders_devices: true)
  end

  def as_a_subsequent_school_user
    @user = create_list(:school_user, 2, :new_visitor, :has_not_seen_privacy_notice, school: school).last
  end

  def when_the_chromebooks_question_has_already_been_answered
    school.preorder_information.update!(will_need_chromebooks: 'no')
  end

  def when_i_sign_in_for_the_first_time
    visit validate_token_url_for(@user)
  end

  def then_i_see_a_welcome_page_for_my_school
    expect(page).to have_text("You’re signed in as #{school.name}")
  end

  def when_i_click_continue
    click_on 'Continue'
  end

  def when_i_click_to_finish_and_go_to_homepage
    click_on 'Finish and go to homepage'
  end

  def then_i_see_a_privacy_notice
    expect(page).to have_current_path(privacy_notice_path)
    expect(page).to have_text('Privacy notice')
  end

  def then_i_see_the_allocation_for_my_school
    heading = I18n.t('page_titles.school_user_welcome_wizard.allocation.title', allocation: device_allocation)
    expect(page).to have_text(heading)
    expect(page).to have_text(@user.school.name)
  end

  def then_i_see_the_order_your_own_page
    expect(page).to have_current_path(school_welcome_wizard_order_your_own_path)
    expect(page).to have_text('You can only order your full allocation if local restrictions are confirmed')
  end

  def then_i_see_the_school_home_page
    expect(page).to have_current_path(school_home_path)
    expect(page).to have_text(school.name)
    expect(page).to have_text('Get devices for your school')
  end

  def then_i_see_the_techsource_account_page
    expect(page).to have_current_path(school_welcome_wizard_techsource_account_path)
    expect(page).to have_text('Use the TechSource website to place orders')
  end

  def then_i_see_the_will_other_order_page
    expect(page).to have_current_path(school_welcome_wizard_will_other_order_path)
    expect(page).to have_text('Do you need to give someone else access?')
  end

  def when_i_choose_yes_and_submit_the_form
    choose 'Yes, I need to add someone'
    within('#school-welcome-wizard-invite-user-yes-conditional') do
      fill_in 'Name', with: 'Amanda Handstand'
      fill_in 'Email address', with: 'amanda@example.com'
      fill_in 'Telephone number', with: '01234 567890'
      choose 'Yes, give them access to the TechSource website'
    end
    click_on 'Continue'
  end

  def then_i_see_information_about_devices_i_can_order
    expect(page).to have_current_path(school_welcome_wizard_devices_you_can_order_path)
    expect(page).to have_text('You can order a range of laptops and tablets')
  end

  def then_im_asked_whether_my_school_will_order_chromebooks
    expect(page).to have_current_path(school_welcome_wizard_chromebooks_path)
    expect(page).to have_text('Will your school’s order include Chromebooks?')
  end

  def when_i_choose_yes_and_submit_the_chromebooks_form
    choose 'Yes, we will need Chromebooks'
    within('#school-welcome-wizard-will-need-chromebooks-yes-conditional') do
      fill_in "School or #{school.responsible_body.humanized_type} domain", with: 'example.com'
      fill_in 'Recovery email address', with: 'admin@trust.com'
    end
    click_on 'Continue'
  end

  def when_i_choose_no_and_submit_the_chromebooks_form
    choose 'No, we do not need Chromebooks'
    click_on 'Continue'
  end

  def then_i_see_information_about_what_happens_next
    expect(page).to have_current_path(school_welcome_wizard_what_happens_next_path)
    expect(page).to have_text('we’ll contact you as soon as you’re able to place orders')
  end

  def when_i_choose_yes_and_click_continue
    choose 'Yes, I will order devices'
    click_on 'Continue'
  end

  def when_i_sign_out
    sign_out
  end

  def and_then_sign_in_again
    visit validate_token_url_for(@user)
    click_on 'Continue'
  end

  def device_allocation
    school.std_device_allocation&.allocation || 0
  end
end
