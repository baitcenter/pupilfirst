class SubmissionDetailsResolver < ApplicationQuery
  property :submission_id

  def submission_details
    {
      submissions: submissions_from_same_set_of_students,
      target_id: target.id,
      target_title: target.title,
      students: students,
      level_number: level.number,
      level_id: level.id,
      target_evaluation_criteria_ids: target.evaluation_criteria.pluck(:id),
      evaluation_criteria: evaluation_criteria,
      review_checklist: review_checklist
    }
  end

  delegate :review_checklist, to: :target

  def submission
    @submission ||= TimelineEvent.find_by(id: submission_id)
  end

  def submissions_from_same_set_of_students
    submissions.includes(:startup_feedback, :timeline_event_grades, :evaluator)
      .order("timeline_events.created_at DESC")
      .select { |s| s.timeline_event_owners.pluck(:founder_id).sort == student_ids }
  end

  def submissions
    TimelineEvent.where(target_id: submission.target_id)
      .joins(:timeline_event_owners)
      .where(timeline_event_owners: { founder_id: student_ids }).distinct
  end

  def student_ids
    @student_ids ||= submission.founders.pluck(:id).sort
  end

  def target
    @target ||= submission.target
  end

  def evaluation_criteria_fields
    %w[name id max_grade pass_grade grade_labels]
  end

  def evaluation_criteria
    # EvaluationCriterion of target OR EvaluationCriteria of submissions
    target_criteria = target.evaluation_criteria.as_json(only: evaluation_criteria_fields)

    submission_criteria = EvaluationCriterion.joins(timeline_event_grades: :timeline_event)
      .where(timeline_events: { id: submissions })
      .distinct.as_json(only: evaluation_criteria_fields)

    (target_criteria + submission_criteria).uniq
  end

  def level
    @level ||= target.level
  end

  def students
    submission.founders.joins(:user).map do |student|
      {
        id: student.id,
        name: student.name
      }
    end
  end

  def authorized?
    return false if submission.blank?

    return false if current_user.faculty.blank?

    current_user.faculty.reviewable_courses.where(id: target.course).exists?
  end
end
