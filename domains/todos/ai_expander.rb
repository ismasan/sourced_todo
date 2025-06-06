# frozen_string_literal: true

module Todos
  class AIExpander < Sourced::Actor

    command(
      :process_item_expansion, 
      list_id: Types::String.present, 
      item_id: Types::String.present, 
      text: String
      ) do |_, cmd|
      event :processing_expansion, cmd.payload
    end

    event :processing_expansion, list_id: String, item_id: String, text: String

    reaction :processing_expansion do |event|
      lines = OpenAI.new.todos_for(event.payload.text)

      if lines.any?
        # stream = stream_for(Todos::List, event.payload.list_id)
        stream = stream_for(event.payload.list_id)
        stream.command Todos::List::ReplaceItem, id: event.payload.item_id, lines:
      end
    end
  end
end
