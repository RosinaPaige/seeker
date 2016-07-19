class Section < ActiveRecord::Base
  searchkick callbacks: :async, highlight: [:content]

  belongs_to :document
  belongs_to :language

  # elasticsearch string length limit is 32766, take caution
  STRING_LEN_LIMIT = 30_000

  def search_data
    {
      content: content,
      section_name: section_name,
      country: document.country&.name,
      year: document.year,
      cycle: document.cycle,
      language: language&.name
    }
  end

  def self.add_section(section_number:, section_name:, content:)
    ((content.length / STRING_LEN_LIMIT) + 1).times do |section_part|
      section_start = section_part * STRING_LEN_LIMIT
      section_end = (section_part + 1) * STRING_LEN_LIMIT
      self.create(section_number: section_number, section_name: section_name, content: content[section_start...section_end], section_part: section_part)
    end
  end
end