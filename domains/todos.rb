# frozen_string_literal: true

module Todos
  # A state entity for a todo item
  class Item < Types::Data
    attribute :id, Types::AutoUUID, writer: true
    attribute :text, Types::NullableDefaultString, writer: true
    attribute :done, Types::Boolean.default(false), writer: true
    attribute :services, Types::Array[String].with_blank_default, writer: true

    def add_service(service)
      self.services = services + [service] unless services.include?(service)
    end
  end

  # An entity to hold todo list state
  class List < Types::Data
    attribute :id, Types::NullableDefaultString, writer: true
    attribute :name, Types::NullableDefaultString, writer: true
    attribute :status, Types::String.options(%w[active archived]).default('active'), writer: true
    attribute :items, Types::Array[Item].with_blank_default, writer: true

    def active? = status == 'active'
    def archived? = status == 'archived'

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

  # The TODO list actor
  # This actor handles commands and events for a List entity.
  # This is the gatekeeper to all todo list state changes.
  # See https://github.com/ismasan/sourced?tab=readme-ov-file#actors
  class ListActor < Sourced::Actor
    module System
      Updated = ::Sourced::Event.define('todos.list.system.updated')
    end

    # Initial state. Ie a blank Todo list.
    state do |id|
      List.new(id:)
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
      if list.active?
        event :created, cmd.payload
      end
    end

    event :created, name: String do |list, evt|
      list.name = evt.payload.name
    end

    command :update_name, name: Types::String.present do |list, cmd|
      if list.name != cmd.payload.name
        event :name_updated, cmd.payload
      end
    end

    event :name_updated, name: String do |list, evt|
      list.name = evt.payload.name
    end

    command :add_item, text: Types::String.present do |list, cmd|
      if list.active?
        event :item_added, id: SecureRandom.uuid, text: cmd.payload.text
      end
    end

    event :item_added, id: String, text: String do |list, evt|
      list.add_item(evt.payload.to_h)
    end

    command :toggle_item, id: Types::String.present do |list, cmd|
      if list.active?
        item = list.find_item(cmd.payload.id)
        raise "Item not found with '#{cmd.payload.id}'" unless item
        if item.done
          event :item_undone, id: item.id
        else
          event :item_done, id: item.id
        end
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
      if list.active?
        item = list.find_item(cmd.payload.id)
        raise "Item not found with '#{cmd.payload.id}'" unless item
        event :item_dispatched, cmd.payload
      end
    end

    event :item_dispatched, id: String, service: String do |list, evt|
      item = list.find_item(evt.payload.id)
      item.add_service(evt.payload.service)
    end

    command :update_item_text, id: Types::String.present, text: Types::String.present do |list, cmd|
      if list.active?
        item = list.find_item(cmd.payload.id)
        raise "Item not found with '#{cmd.payload.id}'" unless item
        event :item_text_updated, cmd.payload
      end
    end

    event :item_text_updated, id: String, text: String do |list, evt|
      item = list.find_item(evt.payload.id)
      item.text = evt.payload.text
    end

    command :remove_item, id: Types::String.present do |list, cmd|
      if list.active?
        item = list.find_item(cmd.payload.id)
        raise "Item not found with '#{cmd.payload.id}'" unless item
        event :item_removed, id: item.id
      end
    end

    event :item_removed, id: String do |list, evt|
      list.remove_item(evt.payload.id)
    end

    command :archive do |list, cmd|
      if list.active?
        event :archived
      end
    end

    event :archived do |list, evt|
      list.status = 'archived'
    end

    command :delete do |list, cmd|
      if list.archived?
        event :deleted
      end
    end

    event :deleted do |list, evt|
    end
  end
end
