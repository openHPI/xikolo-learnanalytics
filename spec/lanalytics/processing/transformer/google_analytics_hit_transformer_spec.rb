require 'rails_helper'

describe Lanalytics::Processing::Transformer::GoogleAnalyticsHitTransformer do
  let(:datasource) do
    datasource = double('GoogleAnalyticsDatasource')
    allow(datasource).to receive(:tracking_id).and_return('UA-424242')
    allow(datasource).to receive(:custom_dimension_index) do |name|
      [:course_id, :item_id, :quiz_type, :section_id, :question_id, :platform,
       :platform_version, :runtime, :runtime_version, :device].index(name) + 1
    end
    allow(datasource).to receive(:custom_metric_index) do |name|
      [:points_percentage, :quiz_attempt, :quiz_needed_time, :video_time].index(name) + 1
    end
    datasource
  end

  before(:each) do
    @original_event = FactoryBot.attributes_for(:amqp_exp_stmt).with_indifferent_access
    @processing_units = [Lanalytics::Processing::Unit.new(:exp_event, @original_event)]
    @load_commands = []
    @pipeline_ctx = OpenStruct.new processing_action: :CREATE

    @geo_id_lookup = double('GoogleAnalyticsGeoIdLookup')
    allow(@geo_id_lookup).to receive(:get).and_return('42')
    @transformer = Lanalytics::Processing::Transformer::GoogleAnalyticsHitTransformer.new(datasource, @geo_id_lookup)
  end

  it 'should transform processing unit to (LoadORM) entity' do
    expect(@geo_id_lookup).to receive(:get).with('DE', 'Potsdam')

    @transformer.transform(
      @original_event,
      @processing_units,
      @load_commands,
      @pipeline_ctx
    )

    expect(@load_commands.length).to eq(1)
    create_hit_command =  @load_commands.first
    expect(create_hit_command).to be_a(Lanalytics::Processing::LoadORM::CreateCommand)
    entity = create_hit_command.entity
    expect(entity).to be_a(Lanalytics::Processing::LoadORM::Entity)

    expect(entity[:v].value).to eq 1
    expect(entity[:tid].value).to eq 'UA-424242'
    expect(entity[:ds].value).to eq :web
    expect(entity[:t].value).to eq :event
    expect(entity[:ec].value).to eq :video
    expect(entity[:ea].value).to eq :video_play
    expect(entity[:qt].value).to eq 1414418348
    expect(entity[:sr].value).to eq '1920x1080'
    expect(entity[:uid].value).to eq (Digest::SHA256.hexdigest '00000001-3100-4444-9999-000000000002')
    expect(entity[:ua].value).to eq ''
    expect(entity[:uip].value).to eq ''
    expect(entity[:geoid].value).to eq '42'
    expect(entity[:cd1].value).to eq '00000002-3100-4444-9999-000000000002'
    expect(entity[:cd2].value).to eq '00000003-3100-4444-9999-000000000002'
    expect(entity[:cm4].value).to eq 67.698807
  end

  let(:load_commands) { [] }
  let(:transform_method) do
    @transformer.method("transform_#{type}_punit_to_create")
  end
  let(:processing_unit) do
    Lanalytics::Processing::Unit.new(type, processing_unit_data)
  end

  subject do
    transform_method.call(processing_unit, load_commands)
    load_commands.first.entity
  end

  describe 'sets data source correctly' do
    let(:type) { 'exp_event' }
    let(:processing_unit_data) do
      {
          user: {
              uuid: SecureRandom.uuid
          },
          verb: {
              type: 'VISITED_ITEM'
          },
          resource: {
              uuid: SecureRandom.uuid,
              type: 'item'
          },
          timestamp: DateTime.now,
          with_result: {},
          in_context: {
              runtime: runtime
          }
      }
    end

    describe 'for Android runtime' do
      let(:runtime) { 'Android' }
      it 'to app' do
        expect(subject[:ds].value).to eq :app
      end
    end

    describe 'for iOS runtime' do
      let(:runtime) { 'iOS' }
      it 'to app' do
        expect(subject[:ds].value).to eq :app
      end
    end

    describe 'for Windows runtime' do
      let(:runtime) { 'Chrome' }
      it 'to web' do
        expect(subject[:ds].value).to eq :web
      end
    end
  end

  describe 'when transforming app events' do
    let(:type) { 'exp_event' }
    let(:processing_unit_data) do
      {
          user: {
              uuid: SecureRandom.uuid
          },
          verb: {
              type: 'VISITED_ITEM'
          },
          resource: {
              uuid: SecureRandom.uuid,
              type: 'item'
          },
          timestamp: DateTime.now,
          with_result: {},
          in_context: {
              runtime: runtime,
              build_version: build_version
          }
      }
    end

    describe 'with Android runtime' do
      let(:runtime) { 'Android' }
      let(:build_version) { '42' }

      it 'sets app name correctly' do
        expect(subject[:an].value).to eq 'Android'
      end
      it 'sets app version correctly' do
        expect(subject[:av].value).to eq '42'
      end
    end

    describe 'with iOS runtime' do
      let(:runtime) { 'iOS' }
      let(:build_version) { '42' }

      it 'sets app name correctly' do
        expect(subject[:an].value).to eq 'iOS'
      end
      it 'sets app version correctly' do
        expect(subject[:av].value).to eq '42'
      end
    end
  end

  describe 'when transforming event with device information' do
    let(:type) { 'exp_event' }
    let(:runtime) { 'Chrome' }
    let(:runtime_version) { '68' }
    let(:platform) { 'Macintosh' }
    let(:platform_version) { '10.13.4' }
    let(:device) { 'Apple Macbook Air' }
    let(:processing_unit_data) do
      {
        user: {
          uuid: SecureRandom.uuid
        },
        verb: {
          type: 'VISITED_ITEM'
        },
        resource: {
          uuid: SecureRandom.uuid,
          type: 'item'
        },
        timestamp: DateTime.now,
        with_result: {},
        in_context: {
          runtime: runtime,
          runtime_version: runtime_version,
          platform: platform,
          platform_version: platform_version,
          device: device
        }
      }
    end

    it 'sets platform correctly' do
      expect(subject[:cd6].value).to eq platform
      expect(subject[:cd7].value).to eq platform_version
    end

    it 'sets runtime_version correctly' do
      expect(subject[:cd8].value).to eq runtime
      expect(subject[:cd9].value).to eq runtime_version
    end

    it 'sets device correctly' do
      expect(subject[:cd10].value).to eq device
    end
  end

  describe 'exp_event' do
    let(:type) { 'exp_event' }

    describe 'video_seek (backward)' do
      let(:processing_unit_data) do
        {
            user: {
                uuid: SecureRandom.uuid
            },
            verb: {
                type: 'VIDEO_SEEK'
            },
            resource: {
                uuid: SecureRandom.uuid,
                type: 'item'
            },
            timestamp: DateTime.now,
            with_result: {},
            in_context: {
                client_id: SecureRandom.uuid,
                course_id: SecureRandom.uuid,
                new_current_time: '5',
                old_current_time: '20'
            }
        }
      end

      it 'is transformed correctly' do
        expect(subject[:t].value).to eq :event
        expect(subject[:ec].value).to eq :video
        expect(subject[:ea].value).to eq :video_seek
        expect(subject[:el].value).to eq :backward
        expect(subject[:cid].value).to eq (Digest::SHA256.hexdigest processing_unit[:in_context][:client_id])
        expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:user][:uuid])
        expect(subject[:qt].value).to eq processing_unit[:timestamp].to_i
        expect(subject[:cd1].value).to eq processing_unit[:in_context][:course_id]
        expect(subject[:cd2].value).to eq processing_unit[:resource][:uuid]
        expect(subject[:cm4].value).to eq processing_unit[:in_context][:old_current_time].to_f
      end
    end

    describe 'video_seek (forward)' do
      let(:processing_unit_data) do
        {
            user: {
                uuid: SecureRandom.uuid
            },
            verb: {
                type: 'VIDEO_SEEK'
            },
            resource: {
                uuid: SecureRandom.uuid,
                type: 'item'
            },
            timestamp: DateTime.now,
            with_result: {},
            in_context: {
                client_id: SecureRandom.uuid,
                course_id: SecureRandom.uuid,
                new_current_time: '20',
                old_current_time: '5'
            }
        }
      end

      it 'is transformed correctly' do
        expect(subject[:t].value).to eq :event
        expect(subject[:ec].value).to eq :video
        expect(subject[:ea].value).to eq :video_seek
        expect(subject[:el].value).to eq :forward
        expect(subject[:cid].value).to eq (Digest::SHA256.hexdigest processing_unit[:in_context][:client_id])
        expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:user][:uuid])
        expect(subject[:qt].value).to eq processing_unit[:timestamp].to_i
        expect(subject[:cd1].value).to eq processing_unit[:in_context][:course_id]
        expect(subject[:cd2].value).to eq processing_unit[:resource][:uuid]
        expect(subject[:cm4].value).to eq processing_unit[:in_context][:old_current_time].to_f
      end
    end

    describe 'video_change_speed' do
      let(:processing_unit_data) do
        {
            user: {
                uuid: SecureRandom.uuid
            },
            verb: {
                type: 'VIDEO_CHANGE_SPEED'
            },
            resource: {
                uuid: SecureRandom.uuid,
                type: 'item'
            },
            timestamp: DateTime.now,
            with_result: {},
            in_context: {
                client_id: SecureRandom.uuid,
                course_id: SecureRandom.uuid,
                current_time: '5',
                new_speed: '1.7'
            }
        }
      end

      it 'is transformed correctly' do
        expect(subject[:t].value).to eq :event
        expect(subject[:ec].value).to eq :video
        expect(subject[:ea].value).to eq :video_change_speed
        expect(subject[:el].value).to eq processing_unit[:in_context][:new_speed]
        expect(subject[:cid].value).to eq (Digest::SHA256.hexdigest processing_unit[:in_context][:client_id])
        expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:user][:uuid])
        expect(subject[:qt].value).to eq processing_unit[:timestamp].to_i
        expect(subject[:cd1].value).to eq processing_unit[:in_context][:course_id]
        expect(subject[:cd2].value).to eq processing_unit[:resource][:uuid]
        expect(subject[:cm4].value).to eq processing_unit[:in_context][:current_time].to_f
      end
    end

    describe 'video_change_quality' do
      let(:processing_unit_data) do
        {
            user: {
                uuid: SecureRandom.uuid
            },
            verb: {
                type: 'VIDEO_CHANGE_QUALITY'
            },
            resource: {
                uuid: SecureRandom.uuid,
                type: 'item'
            },
            timestamp: DateTime.now,
            with_result: {},
            in_context: {
                client_id: SecureRandom.uuid,
                course_id: SecureRandom.uuid,
                current_time: '5',
                new_quality: 'hd'
            }
        }
      end

      it 'is transformed correctly' do
        expect(subject[:t].value).to eq :event
        expect(subject[:ec].value).to eq :video
        expect(subject[:ea].value).to eq :video_change_quality
        expect(subject[:el].value).to eq processing_unit[:in_context][:new_quality]
        expect(subject[:cid].value).to eq (Digest::SHA256.hexdigest processing_unit[:in_context][:client_id])
        expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:user][:uuid])
        expect(subject[:qt].value).to eq processing_unit[:timestamp].to_i
        expect(subject[:cd1].value).to eq processing_unit[:in_context][:course_id]
        expect(subject[:cd2].value).to eq processing_unit[:resource][:uuid]
        expect(subject[:cm4].value).to eq processing_unit[:in_context][:current_time].to_f
      end
    end

    describe 'video_fullscreen (enable)' do
      let(:processing_unit_data) do
        {
            user: {
                uuid: SecureRandom.uuid
            },
            verb: {
                type: 'VIDEO_FULLSCREEN'
            },
            resource: {
                uuid: SecureRandom.uuid,
                type: 'item'
            },
            timestamp: DateTime.now,
            with_result: {},
            in_context: {
                client_id: SecureRandom.uuid,
                course_id: SecureRandom.uuid,
                current_time: '5',
                new_current_fullscreen: 'true'
            }
        }
      end

      it 'is transformed correctly' do
        expect(subject[:t].value).to eq :event
        expect(subject[:ec].value).to eq :video
        expect(subject[:ea].value).to eq :video_fullscreen
        expect(subject[:el].value).to eq :enabled
        expect(subject[:cid].value).to eq (Digest::SHA256.hexdigest processing_unit[:in_context][:client_id])
        expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:user][:uuid])
        expect(subject[:qt].value).to eq processing_unit[:timestamp].to_i
        expect(subject[:cd1].value).to eq processing_unit[:in_context][:course_id]
        expect(subject[:cd2].value).to eq processing_unit[:resource][:uuid]
        expect(subject[:cm4].value).to eq processing_unit[:in_context][:current_time].to_f
      end
    end

    describe 'video_fullscreen (disable)' do
      let(:processing_unit_data) do
        {
            user: {
                uuid: SecureRandom.uuid
            },
            verb: {
                type: 'VIDEO_FULLSCREEN'
            },
            resource: {
                uuid: SecureRandom.uuid,
                type: 'item'
            },
            timestamp: DateTime.now,
            with_result: {},
            in_context: {
                client_id: SecureRandom.uuid,
                course_id: SecureRandom.uuid,
                current_time: '5',
                new_current_fullscreen: 'false'
            }
        }
      end

      it 'is transformed correctly' do
        expect(subject[:t].value).to eq :event
        expect(subject[:ec].value).to eq :video
        expect(subject[:ea].value).to eq :video_fullscreen
        expect(subject[:el].value).to eq :disabled
        expect(subject[:cid].value).to eq (Digest::SHA256.hexdigest processing_unit[:in_context][:client_id])
        expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:user][:uuid])
        expect(subject[:qt].value).to eq processing_unit[:timestamp].to_i
        expect(subject[:cd1].value).to eq processing_unit[:in_context][:course_id]
        expect(subject[:cd2].value).to eq processing_unit[:resource][:uuid]
        expect(subject[:cm4].value).to eq processing_unit[:in_context][:current_time].to_f
      end
    end

    describe 'submitted_lti' do
      let(:processing_unit_data) do
        {
            user: {
                uuid: SecureRandom.uuid
            },
            verb: {
                type: 'SUBMITTED_LTI'
            },
            resource: {
                uuid: SecureRandom.uuid,
                type: 'item'
            },
            timestamp: DateTime.now,
            with_result: {},
            in_context: {
                client_id: SecureRandom.uuid,
                course_id: SecureRandom.uuid,
                points: '5',
                max_points: '10'
            }
        }
      end

      it 'is transformed correctly' do
        expect(subject[:t].value).to eq :event
        expect(subject[:ec].value).to eq :lti
        expect(subject[:ea].value).to eq :submitted_lti
        expect(subject[:cid].value).to eq (Digest::SHA256.hexdigest processing_unit[:in_context][:client_id])
        expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:user][:uuid])
        expect(subject[:qt].value).to eq processing_unit[:timestamp].to_i
        expect(subject[:cd1].value).to eq processing_unit[:in_context][:course_id]
        expect(subject[:cd2].value).to eq processing_unit[:resource][:uuid]
        expect(subject[:cm1].value).to eq (processing_unit[:in_context][:points].to_f / processing_unit[:in_context][:max_points].to_f) * 100
      end
    end

    describe 'visited_announcements (course)' do
      let(:processing_unit_data) do
        {
            user: {
                uuid: SecureRandom.uuid
            },
            verb: {
                type: 'VISITED_ANNOUNCEMENTS'
            },
            resource: {
                uuid: SecureRandom.uuid,
                type: 'course'
            },
            timestamp: DateTime.now,
            with_result: {},
            in_context: {
                client_id: SecureRandom.uuid,
            }
        }
      end

      it 'is transformed correctly' do
        expect(subject[:t].value).to eq :pageview
        expect(subject[:cid].value).to eq (Digest::SHA256.hexdigest processing_unit[:in_context][:client_id])
        expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:user][:uuid])
        expect(subject[:dp].value).to eq "/courses/#{processing_unit[:resource][:uuid]}/announcements"
        expect(subject[:qt].value).to eq processing_unit[:timestamp].to_i
        expect(subject[:cd1].value).to eq processing_unit[:resource][:uuid]
      end
    end

    describe 'visited_announcements (global)' do
      let(:processing_unit_data) do
        {
            user: {
                uuid: SecureRandom.uuid
            },
            verb: {
                type: 'VISITED_ANNOUNCEMENTS'
            },
            resource: {
                uuid: '00000000-0000-0000-0000-000000000000',
                type: 'n/a'
            },
            timestamp: DateTime.now,
            with_result: {},
            in_context: {
                client_id: SecureRandom.uuid
            }
        }
      end

      it 'is transformed correctly' do
        expect(subject[:t].value).to eq :pageview
        expect(subject[:cid].value).to eq (Digest::SHA256.hexdigest processing_unit[:in_context][:client_id])
        expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:user][:uuid])
        expect(subject[:dp].value).to eq '/news'
        expect(subject[:qt].value).to eq processing_unit[:timestamp].to_i
        expect(subject[:cd2]&.value).to be_nil
      end
    end

    describe 'visited_item' do
      let(:processing_unit_data) do
        {
            user: {
                uuid: SecureRandom.uuid
            },
            verb: {
                type: 'VISITED_ITEM'
            },
            resource: {
                uuid: SecureRandom.uuid,
                type: 'item'
            },
            timestamp: DateTime.now,
            with_result: {},
            in_context: {
                client_id: SecureRandom.uuid,
                course_id: SecureRandom.uuid,
                section_id: SecureRandom.uuid
            }
        }
      end

      it 'is transformed correctly' do
        expect(subject[:t].value).to eq :pageview
        expect(subject[:cid].value).to eq (Digest::SHA256.hexdigest processing_unit[:in_context][:client_id])
        expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:user][:uuid])
        expect(subject[:dp].value).to eq "/courses/#{processing_unit[:in_context][:course_id]}/item/#{processing_unit[:resource][:uuid]}"
        expect(subject[:qt].value).to eq processing_unit[:timestamp].to_i
        expect(subject[:cd1].value).to eq processing_unit[:in_context][:course_id]
        expect(subject[:cd2].value).to eq processing_unit[:resource][:uuid]
        expect(subject[:cd4].value).to eq processing_unit[:in_context][:section_id]
      end
    end

    describe 'navigated_next_item' do
      let(:processing_unit_data) do
        {
            user: {
                uuid: SecureRandom.uuid
            },
            verb: {
                type: 'NAVIGATED_NEXT_ITEM'
            },
            resource: {
                uuid: SecureRandom.uuid,
                type: 'item'
            },
            timestamp: DateTime.now,
            with_result: {},
            in_context: {
                client_id: SecureRandom.uuid,
                course_id: SecureRandom.uuid
            }
        }
      end

      it 'is transformed correctly' do
        expect(subject[:t].value).to eq :event
        expect(subject[:ec].value).to eq :navigation
        expect(subject[:ea].value).to eq :navigated_next_item
        expect(subject[:cid].value).to eq (Digest::SHA256.hexdigest processing_unit[:in_context][:client_id])
        expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:user][:uuid])
        expect(subject[:qt].value).to eq processing_unit[:timestamp].to_i
        expect(subject[:cd1].value).to eq processing_unit[:in_context][:course_id]
      end
    end
  end

  describe 'ask_question' do
    let(:type) { 'question' }
    let(:processing_unit_data) do
      {
        id: '00000001-3500-4444-9999-000000000001',
        title: 'Title',
        text: 'Text',
        user_id: SecureRandom.uuid,
        course_id: SecureRandom.uuid,
        technical: false,
        created_at: Time.now
      }
    end

    it 'is transformed correctly' do
      expect(subject[:ds].value).to eq :service
      expect(subject[:t].value).to eq :event
      expect(subject[:ec].value).to eq :pinboard
      expect(subject[:ea].value).to eq :asked_question
      expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:user_id])
      expect(subject[:qt].value).to eq processing_unit[:created_at].to_i
      expect(subject[:cd1].value).to eq processing_unit[:course_id]
      expect(subject[:cd5].value).to eq processing_unit[:id]
      expect(subject[:ua].value).to eq ''
      expect(subject[:uip].value).to eq ''
    end
  end

  describe 'answer_question' do
    let(:type) { 'answer' }
    let(:processing_unit_data) do
      {
        id: '00000002-3500-4444-9999-000000000001',
        user_id: SecureRandom.uuid,
        course_id: SecureRandom.uuid,
        question_id: SecureRandom.uuid,
        technical: false,
        created_at: Time.now
      }
    end

    it 'is transformed correctly' do
      expect(subject[:ds].value).to eq :service
      expect(subject[:t].value).to eq :event
      expect(subject[:ec].value).to eq :pinboard
      expect(subject[:ea].value).to eq :answered_question
      expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:user_id])
      expect(subject[:qt].value).to eq processing_unit[:created_at].to_i
      expect(subject[:cd1].value).to eq processing_unit[:course_id]
      expect(subject[:cd5].value).to eq processing_unit[:question_id]
      expect(subject[:ua].value).to eq ''
      expect(subject[:uip].value).to eq ''
    end
  end

  describe 'answer_accepted' do
    let(:type) { 'answer_accepted' }
    let(:processing_unit_data) do
      {
          id: '00000002-3500-4444-9999-000000000001',
          question_id: SecureRandom.uuid,
          user_id: SecureRandom.uuid,
          course_id: SecureRandom.uuid,
          created_at: Time.now
      }
    end

    it 'is transformed correctly' do
      expect(subject[:ds].value).to eq :service
      expect(subject[:t].value).to eq :event
      expect(subject[:ec].value).to eq :pinboard
      expect(subject[:ea].value).to eq :answer_accepted
      expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:user_id])
      expect(subject[:qt].value).to eq processing_unit[:created_at].to_i
      expect(subject[:cd1].value).to eq processing_unit[:course_id]
      expect(subject[:cd5].value).to eq processing_unit[:question_id]
      expect(subject[:ua].value).to eq ''
      expect(subject[:uip].value).to eq ''
    end
  end

  describe 'comment_question' do
    let(:type) { 'comment' }
    let(:processing_unit_data) do
      {
        id: '00000003-3500-4444-9999-000000000001',
        text: 'Text',
        user_id: SecureRandom.uuid,
        course_id: SecureRandom.uuid,
        commentable_id: SecureRandom.uuid,
        technical: false,
        created_at: Time.now
      }
    end

    it 'is transformed correctly' do
      expect(subject[:ds].value).to eq :service
      expect(subject[:t].value).to eq :event
      expect(subject[:ec].value).to eq :pinboard
      expect(subject[:ea].value).to eq :commented
      expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:user_id])
      expect(subject[:qt].value).to eq processing_unit[:created_at].to_i
      expect(subject[:cd1].value).to eq processing_unit[:course_id]
      expect(subject[:cd5].value).to eq processing_unit[:commentable_id]
      expect(subject[:ua].value).to eq ''
      expect(subject[:uip].value).to eq ''
    end
  end

  describe 'enrollment_created' do
    let(:type) { 'enrollment' }
    let(:processing_unit_data) do
      {
          id: '00000003-3500-4444-9999-000000000001',
          user_id: SecureRandom.uuid,
          course_id: SecureRandom.uuid,
          created_at: Time.now,
          deleted: false
      }
    end

    it 'is transformed correctly' do
      expect(subject[:ds].value).to eq :service
      expect(subject[:t].value).to eq :event
      expect(subject[:ec].value).to eq :course
      expect(subject[:ea].value).to eq :enrolled
      expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:user_id])
      expect(subject[:cd1].value).to eq processing_unit[:course_id]
      expect(subject[:ua].value).to eq ''
      expect(subject[:uip].value).to eq ''
    end
  end

  describe 'user_confirmed' do
    let(:type) { 'user' }
    let(:processing_unit_data) do
      {
          id: '00000003-3500-4444-9999-000000000001',
          course_id: SecureRandom.uuid,
          updated_at: Time.now
      }
    end

    it 'is transformed correctly' do
      expect(subject[:ds].value).to eq :service
      expect(subject[:t].value).to eq :event
      expect(subject[:ec].value).to eq :user
      expect(subject[:ea].value).to eq :confirmed_user
      expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:id])
      expect(subject[:qt].value).to eq processing_unit[:updated_at].to_i
      expect(subject[:ua].value).to eq ''
      expect(subject[:uip].value).to eq ''
    end
  end

  describe 'quiz_submission' do
    let(:type) { 'submission' }
    let(:processing_unit_data) do
      {
          id: '00000003-3500-4444-9999-000000000001',
          item_id: '00000003-3300-4444-9999-000000000001',
          user_id: SecureRandom.uuid,
          course_id: SecureRandom.uuid,
          created_at: Time.now,
          points: 156.2,
          max_points: 180.0,
          attempt: 1,
          quiz_type: 'selftest',
          quiz_submission_time: Time.now.to_s,
          quiz_access_time: (Time.now - 30.minutes).to_s
      }
    end

    it 'is transformed correctly' do
      expect(subject[:ds].value).to eq :service
      expect(subject[:t].value).to eq :event
      expect(subject[:ec].value).to eq :quiz
      expect(subject[:ea].value).to eq :submitted_quiz
      expect(subject[:uid].value).to eq (Digest::SHA256.hexdigest processing_unit[:user_id])
      expect(subject[:qt].value).to eq processing_unit[:quiz_submission_time].to_time.to_i
      expect(subject[:cd1].value).to eq processing_unit[:course_id]
      expect(subject[:cd2].value).to eq processing_unit[:item_id]
      expect(subject[:cd3].value).to eq processing_unit[:quiz_type]
      expect(subject[:cm1].value).to eq (processing_unit[:points] / processing_unit[:max_points]) * 100
      expect(subject[:cm2].value).to eq processing_unit[:attempt]
      expect(subject[:cm3].value).to eq processing_unit[:quiz_submission_time].to_time - processing_unit[:quiz_access_time].to_time
      expect(subject[:ua].value).to eq ''
      expect(subject[:uip].value).to eq ''
    end
  end

  describe 'percentage helper' do
    it 'returns correct result for valid arguments' do
      percentage = @transformer.percentage 2, 5
      expect(percentage).to eq 40
    end

    it 'returns nil if total is nil' do
      percentage = @transformer.percentage 2, nil
      expect(percentage).to be_nil
    end

    it 'returns nil if total is 0' do
      percentage = @transformer.percentage 2, 0
      expect(percentage).to be_nil
    end

    it 'returns nil if total not numeric' do
      percentage = @transformer.percentage 2, '5'
      expect(percentage).to be_nil
    end

    it 'returns nil if value not numeric' do
      percentage = @transformer.percentage '2', 5
      expect(percentage).to be_nil
    end
  end
end
