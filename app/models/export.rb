class Export < ActiveRecord::Base
  require 'fileutils'

  belongs_to :user

  validates :category, presence: true
  validates :export_type, presence: true
  validates :user, presence: true

  after_commit :generate_and_send_export, on: [:create]

  def file
    dir = "exports/#{category}/#{export_type}"

    # create directories if they doesn't exists (exports & type & id)
    FileUtils::mkdir_p dir
    "#{dir}/#{self.filename}"
  end

  def filename
    "#{export_type}-#{self.id}_#{self.created_at.strftime('%d%m%Y')}.xlsx"
  end

  private
  def generate_and_send_export
    case category
      when 'statistics'
        StatisticsExportWorker.perform_async(self.id)
      when 'users'
        UsersExportWorker.perform_async(self.id)
      else
       raise NoMethodError, "Unknown export service for #{category}/#{export_type}"
    end
  end
end
