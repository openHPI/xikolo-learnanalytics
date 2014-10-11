require 'rails_helper'

RSpec.describe Lanalytics::TrackingController, :type => :controller do

  # before( =>each) do
    # expect(Msgr).to receive(:publish).with
    # Msgr.publish(tracking_event, to: "lanalytics.event.stream")
  # end

  describe "POST 'lanalytics/track'" do
    
    it "returns http success" do
      post('track', request_data)
      expect(response).to be_success
    end

    it "should push a message into the RabbitMQ Queue" do
      expect(Msgr).to receive(:publish) do | marshalled_exp_api_stmt, msgr_params |

        expect(marshalled_exp_api_stmt).to be_an_instance_of(String)
        exp_api_stmt = Marshal.load(marshalled_exp_api_stmt)
        expect(exp_api_stmt).to be_an_instance_of(Lanalytics::Model::ExpApiStatement)
        expect(exp_api_stmt.user.uuid).to eq('00000001-3100-4444-9999-000000000001')
        expect(exp_api_stmt.verb.type).to eq(:video_play)
        expect(exp_api_stmt.resource.type).to eq(:Item)
        expect(exp_api_stmt.resource.uuid).to eq('00000003-3100-4444-9999-000000000003')

        expect(msgr_params).to include(:to => 'lanalytics.event.stream')
      end
      post('track', request_data)
      expect(response).to be_success
    end
  end

  def request_data

    return {
      'user' => { 'uuid' => "00000001-3100-4444-9999-000000000001" },
      'verb' => { "type" => "video_play", "verb_id" => "http://lanalytics.open.hpi.de/expapi/verbs/video-play" },
      'resource' => { "type" => "Item", "uuid" => "00000003-3100-4444-9999-000000000003" }
    }
  end


end
