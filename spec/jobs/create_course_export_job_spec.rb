require 'spec_helper'
require 'zipruby'
require 'sidekiq/testing'

describe CreateCourseExportJob do
  before do
    ActiveJob::Base.queue_adapter = :test
    Sidekiq::Testing.fake!
  end

  let(:job) { FactoryGirl.create :job }

  subject { described_class.new.perform}

  it 'should be processed in right queue' do
    expect(CreateCourseExportJob).to be_processed_in :default
  end

  #it 'should process a job' do
  #  expect(CreateCourseExportJob).to receive(:perform_later).once
  #  post :create
  #end
  it 'should zip an object with a password' do
    course_export_job = CreateCourseExportJob.new
    zipname = "result_zip"
    unless File.exists? "test.txt"
      file = File.open "test.txt", "w"
      end
    password = "VeryStrongPassword!"
    result = course_export_job.send(:rename_and_zip,  zipname,  file.path, password, [])
    expect(result).to eq(zipname + ".zip")
    expect(File).to exist(result)
    expect(ZipRuby::Archive.decrypt(result, password)).to eq true

  end

  after do
    File.delete("test.txt") if File.exist?("test.txt")
    File.delete("result_zip") if File.exists?("result_zip")
    File.delete("result_zip.zip") if File.exists?("result_zip.zip")
  end
end