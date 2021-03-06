require 'rails_helper'

describe DailyDigestService do
  include ActiveSupport::Testing::TimeHelpers
  include HtmlSanitizerSpecHelper

  subject { described_class.new }

  around(:each) do |example|
    # Time travel to the test time when running a spec.
    travel_to(Time.zone.parse('2019-07-16T18:00:00+05:30')) do
      example.run
    end
  end

  let(:school) { create :school, :current }

  let(:team_1) { create :startup }
  let(:team_2) { create :team }
  let(:team_3) { create :startup }
  let(:team_4) { create :team, dropped_out_at: 1.day.ago }

  let(:t2_student_regular) { create :founder, startup: team_2 }
  let(:t2_student_digest_inactive) { create :founder, startup: team_2 }
  let(:t2_student_bounced) { create :founder, startup: team_2 }
  let(:t4_student_dropped_out) { create :founder, startup: team_4 }

  let(:community_1) { create :community, school: school, courses: [team_1.course] }
  let(:community_2) { create :community, school: school, courses: [team_1.course, team_2.course] }
  let(:community_3) { create :community, school: school, courses: [team_1.course, team_2.course, team_3.course, team_4.course] }

  let(:t1_user) { team_1.founders.first.user }
  let(:t2_user_1) { t2_student_regular.user }
  let(:t2_user_2) { t2_student_digest_inactive.user }
  let(:t2_user_3) { t2_student_bounced.user }
  let(:t3_user) { team_3.founders.first.user }
  let(:t4_user) { t4_student_dropped_out.user }

  let!(:question_c1) { create :question, community: community_1, creator: t1_user }
  let!(:question_c2_1) { create :question, community: community_2, creator: t2_user_1 }
  let!(:question_c2_2) { create :question, community: community_2, creator: t2_user_2 }
  let!(:question_c3_1) { create :question, community: community_3, creator: t3_user, created_at: 2.days.ago, archived: true }
  let!(:question_c3_2) { create :question, community: community_3, creator: t3_user, created_at: 3.days.ago }
  let!(:question_c3_3) { create :question, community: community_3, creator: t3_user, created_at: 8.days.ago }

  before do
    # Activate daily digest emails for three of the four users.
    [t1_user, t2_user_1, t2_user_3, t3_user, t4_user].each do |user|
      user.update!(preferences: { daily_digest: true })
    end

    # Set email_bounced_at for t2_student_bounced.
    t2_student_bounced.user.update!(email_bounced_at: 1.week.ago)
  end

  describe '#execute' do
    it 'sends digest emails containing details about new and unanswered questions' do
      subject.execute

      open_email(t1_user.email)

      s1 = current_email.subject
      expect(s1).to include(school.name)
      expect(s1).to include('Daily Digest')
      expect(s1).to include('Jul 16, 2019')

      b1 = sanitize_html(current_email.body)

      # The email should link to all three communities.
      expect(b1).to include(community_1.name)
      expect(b1).to include(community_2.name)
      expect(b1).to include(community_3.name)

      # It should include all questions except the archived one and the one from 8 days ago.
      expect(b1).to include(question_c1.title)
      expect(b1).to include(question_c2_1.title)
      expect(b1).to include(question_c2_2.title)
      expect(b1).to include(question_c3_2.title)
      expect(b1).not_to include(question_c3_1.title)
      expect(b1).not_to include(question_c3_3.title)

      open_email(t2_user_1.email)

      s2 = current_email.subject

      # Subject should be identical to first.
      expect(s2).to eq(s1)

      b2 = sanitize_html(current_email.body)

      # It should not have questions from the first community and one from 8 days ago.
      expect(b2).not_to include(question_c1.title)
      expect(b2).to include(question_c2_1.title)
      expect(b2).to include(question_c2_2.title)
      expect(b2).to include(question_c3_2.title)
      expect(b2).not_to include(question_c3_1.title)
      expect(b2).not_to include(question_c3_3.title)

      # User from team 2 with daily digest turned off shouldn't receive the mail.
      open_email(t2_user_2.email)
      expect(current_email).to eq(nil)

      # User from team 2 whose email bounced shouldn't receive email.
      open_email(t2_user_3.email)
      expect(current_email).to eq(nil)

      # Dropped out user shouldn't receive email.
      open_email(t4_user.email)
      expect(current_email).to eq(nil)

      open_email(t3_user.email)

      s3 = current_email.subject

      # Subject should be identical to first.
      expect(s3).to eq(s1)

      b3 = sanitize_html(current_email.body)

      # It should only have the one question from third community.
      expect(b3).not_to include(question_c1.title)
      expect(b3).not_to include(question_c2_1.title)
      expect(b3).not_to include(question_c2_2.title)
      expect(b3).to include(question_c3_2.title)
      expect(b3).not_to include(question_c3_1.title)
      expect(b3).not_to include(question_c3_3.title)
    end

    context 'when there are more than 5 questions with no activity in the past seven days' do
      let!(:question_c3_3) { create :question, community: community_3, creator: t1_user, created_at: 2.days.ago }
      let!(:question_c3_archived) { create :question, community: community_3, creator: t2_user_1, created_at: 3.days.ago, archived: true }
      let!(:question_c3_4) { create :question, community: community_3, creator: t2_user_1, created_at: 3.days.ago }
      let!(:question_c3_5) { create :question, community: community_3, creator: t2_user_2, created_at: 4.days.ago }
      let!(:question_c3_6) { create :question, community: community_3, creator: t3_user, created_at: 5.days.ago }
      let!(:question_c3_7) { create :question, community: community_3, creator: t1_user, created_at: 6.days.ago }
      let!(:question_c3_8) { create :question, community: community_3, creator: t2_user_1, created_at: 6.days.ago }
      let!(:comment) { create :comment, commentable: question_c3_6, creator: t1_user }

      it 'only mails up to 5 such questions' do
        subject.execute

        open_email(t3_user.email)

        b = sanitize_html(current_email.body)

        expect(b).not_to include(question_c1.title)
        expect(b).not_to include(question_c2_1.title)
        expect(b).not_to include(question_c2_2.title)
        expect(b).to include(question_c3_2.title)
        expect(b).not_to include(question_c3_archived.title) # question was archived.
        expect(b).to include(question_c3_3.title)
        expect(b).not_to include(question_c3_8.title)
        expect(b).to include(question_c3_4.title)
        expect(b).to include(question_c3_5.title)
        expect(b).not_to include(question_c3_6.title) # question was commented on.
        expect(b).to include(question_c3_7.title)
        expect(b).not_to include(question_c3_8.title)
      end
    end
  end
end
