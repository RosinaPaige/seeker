require 'open-uri'

class Document < ActiveRecord::Base

  has_many :sections, dependent: :destroy
  belongs_to :country

  has_many :user_tickets

  has_many :collection_documents
  has_many :collections, through: :collection_documents

  after_create :download_and_set_url_local
  before_destroy :delete_local_documents
  before_destroy {collections.clear}


  # document.status is for notifying of failure. TODO: wrap up parsing finished and document status

  DOCUMENT_TYPES = ['State Report', 'Committee of Experts Report', 'Committee of Ministers Recommendation']
  DOCUMENT_TYPES_ID = DOCUMENT_TYPES.zip(0...DOCUMENT_TYPES.length).to_h

  validates :url, presence: true
  validates :country_id, presence: true
  validates :document_type, presence: true, numericality: true, inclusion: { in: (0...DOCUMENT_TYPES.length).to_a }
  validates :year, presence: true, numericality: true
  validates :cycle, presence: true, numericality: true

  # url_local substitution before document is saved
  # Returns a copy of str with the all occurrences of pattern substituted for the second argument
  def clean_url
    "public/storage/#{self.url.gsub(/https?:\/\//, '')}"
  end

  def url_text


    if self.url.include?('.pdf')
      self.url_local&.gsub(/\.pdf$/i, '.txt') || self.clean_url&.gsub(/\.pdf$/i, '.txt')
    else
      first = self.url_local&.gsub(/\.pdf$/i, '.txt') || self.clean_url&.gsub(/\.pdf$/i, '.txt')
      second = first + '.txt'
      return second
    end


  end

  #TODO: wrap status and parsing together
  def finish_parsing!
    self.update_attributes(parsing_finished: true)
  end

  private

  # TODO: check what is at the url. for now, assume is pdf
  # TODO: add support for downloading html
  def download_and_set_url_local
    return if Rails.env.test?
    dir = self.clean_url.split('/')[0...-1].join('/')
    FileUtils.mkdir_p(dir)

    begin
      IO.copy_stream(open(self.url), self.clean_url)
    rescue StandardError => e
      raise "There is nothing at the supplied URL"
    end

    self.update_attributes(url_local: self.clean_url)
  end

  def delete_local_documents
    return if Rails.env.test?
    FileUtils.rm(self.url_local)
    FileUtils.rm(self.url_text)
  rescue
  end
end
