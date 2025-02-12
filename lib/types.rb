require 'plumb'

module Types
  include Plumb::Types

  LoginForm = Hash[
    username: String.present
  ]
end
