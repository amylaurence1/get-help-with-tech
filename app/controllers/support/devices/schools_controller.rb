class Support::Devices::SchoolsController < Support::BaseController
  def invite
    school = School.find_by!(urn: params[:school_urn])
    success = school.invite_school_contact_if_possible!
    if success
      flash[:success] = I18n.t('support.schools.invite.success', name: school.name)
    else
      flash[:warning] = I18n.t('support.schools.invite.failure', name: school.name)
    end
    redirect_to support_devices_responsible_body_path(school.responsible_body)
  end
end
