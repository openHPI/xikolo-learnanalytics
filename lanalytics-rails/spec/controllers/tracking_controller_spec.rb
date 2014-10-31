require 'rails_helper'

RSpec.describe Lanalytics::TrackingController, :type => :controller do

  # before( =>each) do
    # expect(Msgr).to receive(:publish).with
    # Msgr.publish(tracking_event, to: "lanalytics.event.stream")
  # end

    
  it "returns http success" do
    post('track', request_data)
    expect(response).to be_success
  end

  it "should push a message into the RabbitMQ Queue" do
    
    expect(Msgr).to receive(:publish) do | exp_stmt_as_hash, msgr_params |

      expect(exp_stmt_as_hash).to be_a(Hash)
      exp_stmt = Lanalytics::Model::ExpApiStatement.new_from_json(exp_stmt_as_hash)
      expect(exp_stmt).to be_an_instance_of(Lanalytics::Model::ExpApiStatement)
      expect(exp_stmt.user.uuid).to eq('00000001-3100-4444-9999-000000000001')
      expect(exp_stmt.verb.type).to eq(:VIDEO_PLAY)
      expect(exp_stmt.resource.type).to eq(:ITEM)
      expect(exp_stmt.resource.uuid).to eq('00000003-3100-4444-9999-000000000003')

      expect(msgr_params).to include(:to => 'xikolo.web.event.create')
    end

    post('track', request_data)
    expect(response).to be_success
  end

  def request_data

    return {
      'user' => { 'uuid' => "00000001-3100-4444-9999-000000000001" },
      'verb' => { "type" => "video_play", "verb_id" => "http://lanalytics.open.hpi.de/expapi/verbs/video-play" },
      'resource' => { "type" => "Item", "uuid" => "00000003-3100-4444-9999-000000000003" }
    }
  end


end
