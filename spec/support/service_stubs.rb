# frozen_string_literal: true

module Stub
  class << self
    def url(service, path)
      Addressable::URI.parse(Restify::Registry.fetch(service).uri).join(path)
    end

    def request(service, http_method, path = '', **request_params)
      # Prefix the path with the service's base URL
      uri_matcher = "#{Restify::Registry.fetch(service).uri}#{path}"

      WebMock.stub_request(http_method, uri_matcher).tap do |stub|
        stub.with(request_params) unless request_params.empty?
      end
    end

    def response(body: nil, links: {}, **kwargs)
      response = {status: 200, body:, headers: {}}.merge kwargs

      unless links.empty?
        links = links.map {|name, value| "<#{value}>;rel=#{name}" }
          .unshift(response[:headers]['Link'])
          .compact

        response[:headers]['Link'] = links.join ', '
      end

      response
    end

    def json(json, **kwargs)
      body = JSON.dump(json)
      headers = kwargs.delete(:headers) || {}

      response(
        body:,
        headers: {
          'Content-Type' => 'application/json;charset=utf-8',
          'Content-Length' => body.length,
        }.merge(headers),
        **kwargs,
      )
    end
  end
end
