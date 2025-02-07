module Todos
  Item = Struct.new(:id, :text, :done, keyword_init: true) do
    def self.build(attrs = {})
      attrs = { id: SecureRandom.uuid, done: false }.merge(attrs)
      new(**attrs)
    end
  end

  List = Struct.new(:id, :items, keyword_init: true)

  class ListActor < Sourced::Actor
    state do |id|
      List.new(id:, items: [])
    end

    # All events, not up to
    def history
      events(upto: nil)
    end

    command :add_item, text: Types::String.present do |list, cmd|
      event :item_added, id: SecureRandom.uuid, text: cmd.payload.text
    end

    event :item_added, id: String, text: String do |list, evt|
      list.items << Item.build(evt.payload.to_h)
    end

    command :toggle_item, id: Types::String.present do |list, cmd|
      item = list.items.find { |i| i.id == cmd.payload.id }
      raise "Item not found with '#{cmd.payload.id}'" unless item
      event :item_toggled, id: item.id
    end

    event :item_toggled, id: String do |list, evt|
      item = list.items.find { |i| i.id == evt.payload.id }
      item.done = !item.done
    end
  end
end
