class ApplicantsController < ApplicationController
  # GET /applicants/:token/enroll
  def enroll
    @applicant = Applicant.find_by(login_token: params[:token])

    if valid_applicant?
      student = Applicants::CreateStudentService.new(@applicant).create(session[:applicant_tag] || 'Public Signup')
      sign_in student.user
      flash[:success] = "Welcome to #{current_school.name}!"
      redirect_to after_sign_in_path_for(student.user)
    else
      flash[:error] = 'User authentication failed. The link you followed appears to be invalid.'
      redirect_to new_user_session_path
    end
  end

  private

  def valid_applicant?
    public_courses = current_school.courses.where(public_signup: true)
    @applicant.present? && public_courses.where(id: @applicant.course_id).exists?
  end
end
