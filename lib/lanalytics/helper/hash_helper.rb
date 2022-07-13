# frozen_string_literal: true

module Lanalytics::Helper::HashHelper
  # http://stackoverflow.com/questions/8706930/converting-nested-hash-keys-from-camelcase-to-snake-case-in-ruby
  def underscore_key(k)
    k.to_s.underscore.to_sym
  end

  def hash_keys_to_underscore(value)
    case value
      when Array
        value.map {|v| hash_keys_to_underscore(v) }
      when Hash
        Hash[value.map {|k, v| [underscore_key(k), hash_keys_to_underscore(v)] }]
      else
        value
    end
  end
end
