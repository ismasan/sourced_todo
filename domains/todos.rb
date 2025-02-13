module Todos
  class Item < Types::Data
    attribute :id, Types::String.default { SecureRandom.uuid }, writer: true
    attribute :text, String, writer: true
    attribute :done, Types::Boolean.default(false), writer: true
    attribute :services, Types::Array[String].default([].freeze), writer: true

    def add_service(service)
      self.services = services + [service] unless services.include?(service)
    end
  end

  class List < Types::Data
    attribute :id, String, writer: true
    attribute :name, String, writer: true
    attribute :items, Types::Array[Item].default([].freeze), writer: true

    def find_item(id)
      items.find { |i| i.id == id }
    end

    def add_item(args = {})
      self.items = items + [Item.new(args)]
    end

    def remove_item(id)
      self.items = items.reject { |i| i.id == id }
    end
  end

  class ListActor < Sourced::Actor
    module System
      Updated = ::Sourced::Event.define('todos.list.system.updated')
    end

    state do |id|
      List.new(id:, name: nil, items: [])
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

    command :create, name: Types::String.present do |list, cmd|
      event :created, cmd.payload
    end

    event :created, name: String do |list, evt|
      list.name = evt.payload.name
    end

    command :add_item, text: Types::String.present do |list, cmd|
      event :item_added, id: SecureRandom.uuid, text: cmd.payload.text
    end

    event :item_added, id: String, text: String do |list, evt|
      list.add_item(evt.payload.to_h)
    end

    command :toggle_item, id: Types::String.present do |list, cmd|
      item = list.find_item(cmd.payload.id)
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
      item.add_service(evt.payload.service)
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
      list.remove_item(evt.payload.id)
    end
  end
end
