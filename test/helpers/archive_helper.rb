# frozen_string_literal: true

# Provides methods to help testing archives of accounting periods
module ArchiveHelper
  # Force the generation of the archive now.
  # Then extract it, then check its contents, then delete the archive, finally delete the extracted content
  def assert_archive(accounting_period)
    assert_not_nil accounting_period, 'AccountingPeriod was not created'

    archive_worker = ArchiveWorker.new
    archive_worker.perform(accounting_period.id)

    assert FileTest.exist?(accounting_period.archive_file), 'ZIP archive was not generated'

    dest = extract_archive(accounting_period)

    # Check archive matches
    file = check_integrity(dest)

    archive = File.read("#{dest}/#{file}")
    archive_json = JSON.parse(archive)
    invoices = Invoice.where(
      'created_at >= :start_date AND created_at <= :end_date',
      start_date: accounting_period.start_at.to_datetime, end_date: accounting_period.end_at.to_datetime
    )

    assert_equal invoices.count, archive_json['invoices'].count
    assert_equal accounting_period.footprint, archive_json['period_footprint']

    require 'version'
    assert_equal Version.current, archive_json['software']['version']

    # we clean up the files before quitting
    FileUtils.rm_rf(dest)
    FileUtils.rm_rf(accounting_period.archive_folder)
  end

  private

  # Extract the archive to the temporary folder
  def extract_archive(accounting_period)
    require 'tmpdir'
    require 'fileutils'
    dest = "#{Dir.tmpdir}/accounting/#{accounting_period.id}"
    FileUtils.mkdir_p "#{dest}/accounting"
    Zip::File.open(accounting_period.archive_file) do |zip_file|
      # Handle entries one by one
      zip_file.each do |entry|
        # Extract to file/directory/symlink
        entry.extract("#{dest}/#{entry.name}")
      end
    end
    dest
  end

  def check_integrity(extracted_path)
    require 'integrity/checksum'
    sumfile = File.read("#{dest}/checksum.sha256").split("\t")
    assert_equal sumfile[0], Integrity::Checksum.file("#{extracted_path}/#{sumfile[1]}"), 'archive checksum does not match'
    sumfile[1]
  end
end
