require 'msgr'
require 'factory_girl'
require_relative '../spec/factories/lanalytics/processing/amqp_event_data_factory.rb'


FactoryGirl.attributes_for(:amqp_course)
# FactoryGirl.attributes_for(:amqp_item)
FactoryGirl.attributes_for(:amqp_enrollment)

course1_event_data = FactoryGirl.attributes_for(:amqp_course)
course1_event_data[:title] = "Course 1"
course2_event_data = FactoryGirl.attributes_for(:amqp_course)
course2_event_data[:id] = SecureRandom.uuid
course2_event_data[:title] = "Course 2"

Msgr.publish(course1_event_data, to: 'xikolo.course.course.create')
Msgr.publish(course2_event_data, to: 'xikolo.course.course.update')





# message = {:id=>"5eabdf59-d754-4e50-9c21-d002a3710da5", :title=>"Mumap Gerardp 123123123", :start_date=>nil, :display_start_date=>nil, :end_date=>nil, :abstract=>"", :description_rtid=>"848a1364-c3d7-440d-bc28-cb7790b7c07d", :visual_id=>nil, :lang=>"de", :categories=>[], :teacher_ids=>[], :course_code=>"muma", :status=>"preparation", :vimeo_id=>nil, :has_teleboard=>false, :records_released=>false, :url=>"/courses/5eabdf59-d754-4e50-9c21-d002a3710da5", :enrollment_delta=>0, :alternative_teacher_text=>"", :external_course_url=>"", :forum_is_locked=>false, :affiliated=>false, :hidden=>false, :welcome_mail=>""}

FactoryGirl.attributes_for(:amqp_user)

