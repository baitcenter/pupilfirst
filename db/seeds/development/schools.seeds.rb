after 'schools' do
  puts 'Seeding schools (dev)'

  school = School.first

  # Attach a logo (on light) for school.
  unless school.logo_on_light_bg.attached?
    school.logo_on_light_bg.attach(
      io: File.open(Rails.root.join('spec', 'support', 'uploads', 'files', 'logo_lipsum_on_light_bg.png')),
      filename: 'logo_lipsum_on_light_bg.png'
    )
  end

  # Attach a logo (on dark) for school.
  unless school.logo_on_dark_bg.attached?
    school.logo_on_dark_bg.attach(
      io: File.open(Rails.root.join('spec', 'support', 'uploads', 'files', 'logo_lipsum_on_dark_bg.png')),
      filename: 'logo_lipsum_on_dark_bg.png'
    )
  end

  # Attach an icon for school.
  unless school.icon.attached?
    school.icon.attach(
      io: File.open(Rails.root.join('spec', 'support', 'uploads', 'files', 'icon_pupilfirst.png')),
      filename: 'icon_pupilfirst.png'
    )
  end

  # Create another school without any customizations.
  School.where(name: 'Second School').first_or_create!
end
