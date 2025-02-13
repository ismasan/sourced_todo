# frozen_string_literal: true

require 'plumb'

module Types
  # See https://github.com/ismasan/plumb
  include Plumb::Types

  NullableDefaultString = String.nullable.default(nil)
  AutoUUID = String.default { SecureRandom.uuid }

  LoginForm = Hash[
    username: String.present
  ]

  # A Plumb helper to provide a blank default value for a type
  # example:
  #   attribute :services, Types::Array[String].with_blank_default
  DEFAULTS = {
    ::Array => Plumb::BLANK_ARRAY,
    ::Hash => Plumb::BLANK_HASH,
    ::String => '',
    ::Integer => 0,
    ::Float => 0.0
  }.freeze

  Plumb.policy :with_blank_default, helper: true do |type|
    primitive = Array(type.metadata[:type]).first
    if (df = DEFAULTS[primitive])
      type.default(df)
    else
      type
    end
  end
end
