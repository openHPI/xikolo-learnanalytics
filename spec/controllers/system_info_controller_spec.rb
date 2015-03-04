require 'spec_helper'

describe SystemInfoController, type: :controller do
  subject    { JSON[response.body].with_indifferent_access }
  let(:default_params) { {format: 'json'} }
  let(:params)  { {} }

  describe 'GET show' do
    let(:deb_version) { nil }
    before do
      ENV['DEB_VERSION'] = deb_version
      get :show, id: -1, format: 'json'
    end
    after do
      ENV.delete 'DEB_VERSION'
    end

    it 'should return a running state' do
      expect(subject[:running]).to eq true
    end

    context 'with debian version number' do
      let(:deb_version) { '1.0+t201310251852+b194-1' }
      it 'should return the package version' do
        expect(subject[:version]).to eq '1.0'
      end

      it 'should return the build timestamp' do
        expect(subject[:build_time]).to eq DateTime.new(2013, 10, 25, 18, 52).iso8601
      end

      it 'should return the build number' do
        expect(subject[:build_number]).to eq 194
      end
    end

    context 'without debian version number (development' do
      let(:deb_version) { nil }
      it 'should return the package version' do
        expect(subject[:version]).to eq '0.0'
      end
      it 'should return the build timestamp' do
        t = DateTime.strptime(Time.now.utc.strftime('%Y%m%d%H%M'), '%Y%m%d%H%M')
        expect(subject[:build_time]).to eq t.iso8601
      end

      it 'should return the build number' do
        expect(subject[:build_number]).to eq 0
      end
    end

    it 'should return the hostname' do
      expect(subject[:hostname]).to eq Socket.gethostname
    end
  end
end
