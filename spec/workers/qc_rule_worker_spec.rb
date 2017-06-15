require 'spec_helper'
require 'sidekiq/testing'
require 'acfs/rspec'

describe QcRuleWorker do
  before do
    ActiveJob::Base.queue_adapter = :test
    Sidekiq::Testing.fake!
  end
  let(:qc_rule) {FactoryGirl.create :qc_rule}
  let(:qc_rule2) {FactoryGirl.create :qc_rule}
  let(:test_course) {FactoryGirl.create :test_course}
  let(:qc_alert_open) { FactoryGirl.create :qc_alert, {qc_rule_id: qc_rule.id, status: 'open', course_id: '00000001-3300-4444-9999-000000000001'} }
  let(:qc_alert_closed) { FactoryGirl.create :qc_alert, {qc_rule_id: qc_rule2.id, status: 'closed', course_id: '00000001-3300-4444-9999-000000000002'} }
  let(:qc_alert_closed_with_data) { FactoryGirl.create :qc_alert, {qc_rule_id: qc_rule.id, status: 'closed', course_id: test_course.id, qc_alert_data: {"resource_id"=>"00000001-3300-4444-9999-000000000003"} } }
  let(:qc_alert_open_with_data) { FactoryGirl.create :qc_alert, {qc_rule_id: qc_rule.id, status: 'open', course_id: test_course.id,  qc_alert_data: {"resource_id"=>"00000001-3300-4444-9999-000000000003"}} }

  subject { described_class.new.perform}
  it 'should update open alert annotation' do
    qc_rule
    qc_alert_open
    @qc_worker = QcRuleWorker.new
    @qc_worker.send(:update_or_create_qc_alert, qc_rule.id, '00000001-3300-4444-9999-000000000001','high','annotation')
    updated_alert = QcAlert.find_by(qc_rule_id: qc_rule.id, course_id: '00000001-3300-4444-9999-000000000001')
    expect(updated_alert.annotation).to eq('annotation')
  end

  it 'should reopen closed alert' do
    qc_rule2
    qc_alert_closed
    @qc_worker = QcRuleWorker.new
    expect(qc_alert_closed.status).to eq('closed')
    expect(qc_alert_closed.annotation).to eq('')
    @qc_worker.send(:update_or_create_qc_alert, qc_rule2.id, '00000001-3300-4444-9999-000000000002','high','annotation')
    updated_alert = QcAlert.find_by(qc_rule_id: qc_rule2.id, course_id: '00000001-3300-4444-9999-000000000002')
    expect(updated_alert.severity).to eq('high')
    expect(updated_alert.annotation).to eq('annotation')
    expect(updated_alert.status).to eq('open')
  end

  it 'should reopen closed alert with data' do
    qc_rule
    qc_alert_closed_with_data
    @qc_worker = QcRuleWorker.new
    expect(qc_alert_closed_with_data.status).to eq('closed')
    expect(qc_alert_closed_with_data.annotation).to eq('')
    @qc_worker.send(:update_or_create_qc_alert_with_data, qc_rule.id, test_course.id, 'medium','annotation', '00000001-3300-4444-9999-000000000003', {"resource_id"=>"00000001-3300-4444-9999-000000000003"})
    updated_alert = QcAlert.where(qc_rule_id: qc_rule.id, course_id: test_course.id).where("(qc_alert_data->>'resource_id')= ?", '00000001-3300-4444-9999-000000000003').first
    expect(updated_alert.severity).to eq('medium')
    expect(updated_alert.annotation).to eq('annotation')
    expect(updated_alert.status).to eq('open')
  end

  it 'should create a new alert' do
    @qc_worker = QcRuleWorker.new
    @qc_worker.send(:update_or_create_qc_alert, '00000001-3300-4444-9999-000000000003', '00000001-3300-4444-9999-000000000003','low','annotation')
    updated_alert = QcAlert.find_by(qc_rule_id: '00000001-3300-4444-9999-000000000003', course_id: '00000001-3300-4444-9999-000000000003')
    expect(updated_alert.annotation).to eq('annotation')
    expect(updated_alert.severity).to eq('low')
  end

  it 'should create a new alert with data' do
    @qc_worker = QcRuleWorker.new
    @qc_worker.send(:update_or_create_qc_alert_with_data, '00000001-3300-4444-9999-000000000003', '00000001-3300-4444-9999-000000000003','low','annotation', '00000001-3300-4444-9999-000000000003', {"resource_id"=>"00000001-3300-4444-9999-000000000003"})
    new_alert = QcAlert.where(qc_rule_id: '00000001-3300-4444-9999-000000000003', course_id: '00000001-3300-4444-9999-000000000003').where("(qc_alert_data->>'resource_id')= ?", '00000001-3300-4444-9999-000000000003').first
    expect(new_alert.annotation).to eq('annotation')
    expect(new_alert.severity).to eq('low')
    expect(new_alert.qc_alert_data).to eq({"resource_id"=>"00000001-3300-4444-9999-000000000003"})
  end

  it 'should update an alert with data' do
    qc_rule
    test_course
    qc_alert_open_with_data
    @qc_worker = QcRuleWorker.new
    @qc_worker.send(:update_or_create_qc_alert_with_data, qc_rule.id, test_course.id,'medium','annotation', '00000001-3300-4444-9999-000000000003', {"resource_id"=>"00000001-3300-4444-9999-000000000003"})
    updated_alert = QcAlert.where(qc_rule_id: qc_rule.id, course_id: test_course.id).where("(qc_alert_data->>'resource_id')= ?", '00000001-3300-4444-9999-000000000003').first
    expect(updated_alert.annotation).to eq('annotation')
    expect(updated_alert.severity).to eq('medium')
    expect(updated_alert.qc_alert_data).to eq({"resource_id"=>"00000001-3300-4444-9999-000000000003"})
  end

  it 'should close an alert' do
    qc_rule
    qc_alert_open
    expect(qc_alert_open.status).to eq('open')
    @qc_worker = QcRuleWorker.new
    @qc_worker.send(:find_and_close_qc_alert, qc_rule.id, qc_alert_open.course_id )
    updated_alert = QcAlert.find_by(qc_rule_id: qc_rule.id, course_id: qc_alert_open.course_id)
    expect(updated_alert.status).to eq('closed')
  end

  it 'should close an alert with data' do
    qc_rule
    qc_alert_open_with_data
    expect(qc_alert_open.status).to eq('open')
    @qc_worker = QcRuleWorker.new
    @qc_worker.send(:find_and_close_qc_alert_with_data, qc_rule.id, test_course.id, "00000001-3300-4444-9999-000000000003",   )
    updated_alert = QcAlert.where(qc_rule_id: qc_rule.id, course_id: test_course.id).where("(qc_alert_data->>'resource_id')= ?", '00000001-3300-4444-9999-000000000003').first
    expect(updated_alert.status).to eq('closed')
  end

  it 'should return only active courses' do
    course = Xikolo::Course::Course.new(:start_date => 1.day.ago, :end_date => 100.days.from_now, :status => 'active')
    @qc_worker = QcRuleWorker.new
    result = @qc_worker.send(:course_is_active, course )
    expect(result).to eq(true)
  end

  it 'should not return not active courses' do
    course = Xikolo::Course::Course.new(:start_date => 1.day.ago, :end_date => 100.days.from_now, :status => 'archived')
    @qc_worker = QcRuleWorker.new
    result = @qc_worker.send(:course_is_active, course )
    expect(result).to eq(false)
  end

  it 'should not courses that are not running anymore' do
    course = Xikolo::Course::Course.new(:start_date => 100.days.ago, :end_date => 10.days.ago, :status => 'archived')
    @qc_worker = QcRuleWorker.new
    result = @qc_worker.send(:course_is_active, course )
    expect(result).to eq(false)
  end

  #it 'should create json' do
  #  @qc_worker = QcRuleWorker.new
  #  result = @qc_worker.send(:create_json, '00000001-3300-4444-9999-000000000003')
  #  expected_result = {"resource_id"=>"00000001-3300-4444-9999-000000000003"}
  #  expect(result).to eq (expected_result)
  #end
end