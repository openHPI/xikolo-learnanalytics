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
    course_export_job = CreateExportJob.new
    csv_name = 'test.csv'
    unless File.exists? "test.txt"
      file = File.open "test.txt", "w"
    end
    unless File.exists? "excel.txt"
      excel_file = File.open "excel.txt", "w"
    end
    password = "VeryStrongPassword!"
    result = course_export_job.send(:rename_and_zip, csv_name , file.path, 'excel.xlsx', excel_file.path, password, [])
    expect(result).to eq(csv_name[0..-5] + ".zip")
    expect(File).to exist(result)
    expect(ZipRuby::Archive.decrypt(result, password)).to eq true

  end

  after do
    File.delete('test.txt') if File.exist?('test.txt')
    File.delete('excel.txt') if File.exist?('excel.txt')
    File.delete('excel.csv') if File.exist?('excel.csv')
    File.delete('test.csv') if File.exists?('test.csv')
    File.delete('test.csv.zip') if File.exists?('test.csv.zip')
  end
end