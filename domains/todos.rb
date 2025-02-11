module Todos
  Item = Struct.new(:id, :text, :done, :services, keyword_init: true) do
    def self.build(attrs = {})
      attrs = { id: SecureRandom.uuid, done: false }.merge(attrs)
      attrs[:services] ||= []
      new(**attrs)
    end
  end

  List = Struct.new(:id, :items, keyword_init: true) do
    def find_item(id)
      items.find { |i| i.id == id }
    end
  end

  class ListActor < Sourced::Actor
    module System
      Updated = ::Sourced::Event.define('todos.list.system.updated')
    end

    state do |id|
      List.new(id:, items: [])
    end

    # All events, not up to
    def history
      events(upto: nil)
    end

    # This runs in the same transaction
    # as commiting new events to the backend
    # Here we publish an ephemeral event
    # so that the UI can react to it
    # In future, Sourced will have a special DSL for this
    sync do |state, command, events|
      Sourced.config.backend.pubsub.publish('system', command.follow(System::Updated))
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
      if item.done
        event :item_undone, id: item.id
      else
        event :item_done, id: item.id
      end
    end

    event :item_done, id: String do |list, evt|
      item = list.find_item(evt.payload.id)
      item.done = true
    end

    event :item_undone, id: String do |list, evt|
      item = list.find_item(evt.payload.id)
      item.done = false
    end

    command :notify_dispatched, id: Types::String.present, service: String do |list, cmd|
      item = list.find_item(cmd.payload.id)
      raise "Item not found with '#{cmd.payload.id}'" unless item
      event :item_dispatched, cmd.payload
    end

    event :item_dispatched, id: String, service: String do |list, evt|
      item = list.find_item(evt.payload.id)
      item.services << evt.payload.service unless item.services.include?(evt.payload.service)
    end

    command :update_item_text, id: Types::String.present, text: Types::String.present do |list, cmd|
      item = list.find_item(cmd.payload.id)
      raise "Item not found with '#{cmd.payload.id}'" unless item
      event :item_text_updated, cmd.payload
    end

    event :item_text_updated, id: String, text: String do |list, evt|
      item = list.find_item(evt.payload.id)
      item.text = evt.payload.text
    end

    command :remove_item, id: Types::String.present do |list, cmd|
      item = list.find_item(cmd.payload.id)
      raise "Item not found with '#{cmd.payload.id}'" unless item
      event :item_removed, id: item.id
    end

    event :item_removed, id: String do |list, evt|
      list.items.reject! { |i| i.id == evt.payload.id }
    end
  end
end
