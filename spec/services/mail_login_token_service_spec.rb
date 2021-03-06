require 'rails_helper'

describe MailLoginTokenService do
  subject { described_class.new(user, referer, shared_device) }

  let(:school) { create :school, :current }
  let(:user) { create :user, school: school }
  let(:shared_device) { [true, false].sample }
  let(:domain) { school.domains.where(primary: true).first }
  let(:referer) { Faker::Internet.url(domain.fqdn) }

  context 'When an User is passed on to the service' do
    subject { described_class.new(user, referer, shared_device) }

    describe '#execute' do
      it 'generates new login token for user' do
        expect do
          subject.execute
        end.to(change { user.reload.login_token })
      end

      it 'emails login link to user' do
        subject.execute

        open_email(user.email)

        expect(current_email.subject).to eq("Log in to #{school.name}")
        expect(current_email.body).to include("http://#{domain.fqdn}/users/token?")
        expect(current_email.body).to include("referer=#{CGI.escape(referer)}")
        expect(current_email.body).to include("token=#{user.reload.login_token}")
      end
    end
  end

  context 'When an Applicant is passed on to the service' do
    let(:course) { create :course, school: school }
    let(:applicant) { create :applicant, course: course }
    subject { described_class.new(applicant) }

    describe '#execute' do
      it 'generates new login token for applicant' do
        expect do
          subject.execute
        end.to(change { applicant.reload.login_token })
      end

      it 'emails login link to applicant' do
        subject.execute

        open_email(applicant.email)

        expect(current_email.subject).to eq("Verify Your Email Address")
        expect(current_email.body).to include("http://#{domain.fqdn}/applicants/#{applicant.reload.login_token}")
      end
    end
  end
end
