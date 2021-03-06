module Types
  class TeamType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :level_id, ID, null: false
    field :students, [Types::StudentType], null: false

    def students
      object.founders.map do |student|
        student_attributes = { id: student.id, name: student.name, title: student.title }

        if student.user.avatar.attached?
          student_attributes[:avatar_url] =
            Rails.application.routes.url_helpers.rails_representation_path(student.user.avatar_variant(:thumb), only_path: true)
        end

        student_attributes
      end
    end
  end
end
