# frozen_string_literal: true

module Todos
  # A state entity for a todo item
  class ItemState < Types::Data
    attribute :id, Types::AutoUUID, writer: true
    attribute :text, Types::NullableDefaultString, writer: true
    attribute :expanding, Types::Boolean.default(false), writer: true
    attribute :done, Types::Boolean.default(false), writer: true
    attribute :services, Types::Array[String].with_blank_default, writer: true

    def too_long?
      text.size > 40
    end

    def add_service(service)
      self.services = services + [service] unless services.include?(service)
    end
  end

  # An entity to hold todo list state
  class ListState < Types::Data
    attribute :id, Types::NullableDefaultString, writer: true
    attribute :name, Types::NullableDefaultString, writer: true
    attribute :status, Types::String.options(%w[active archived deleted]).default('active'), writer: true
    attribute :items, Types::Array[ItemState].with_blank_default, writer: true
    attribute :duplicated_item, ItemState.nullable.default(nil), writer: true
    attribute :paused, Types::Boolean.default(false), writer: true

    def active? = status == 'active'
    def archived? = status == 'archived'
    def deleted? = status == 'deleted'

    def find_item(id)
      items.find { |i| i.id == id }
    end

    def find_item_by_text(text)
      text = text.downcase.strip
      items.find { |i| i.text.downcase.strip == text }
    end

    def add_item(args = {})
      self.items = items + [ItemState.new(args)]
    end

    def remove_item(id)
      self.items = items.reject { |i| i.id == id }
    end
  end

  # The TODO list actor
  # This actor handles commands and events for a List entity.
  # This is the gatekeeper to all todo list state changes.
  # See https://github.com/ismasan/sourced?tab=readme-ov-file#actors
  class List < Sourced::Actor
    module System
      Updated = ::Sourced::Event.define('todos.list.system.updated')
    end

    # Initial state. Ie a blank Todo list.
    state do |id|
      ListState.new(id:)
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
      return unless list.active?
      event :created, cmd.payload
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
      return unless list.active?

      validate_duplicated_item(list, cmd.payload.text) do
        event :item_added, id: SecureRandom.uuid, text: cmd.payload.text
      end
    end

    command :expand_item, id: Types::String.present do |list, cmd|
      return unless list.active?
      return unless list.find_item(cmd.payload.id)

      event :expansion_started, cmd.payload
    end

    event :expansion_started, id: String do |list, event|
      item = list.find_item(event.payload.id)
      item.expanding = true
    end

    reaction_with_state :expansion_started do |list, event|
      item = list.find_item(event.payload.id)

      stream_for(Todos::AIExpander).command(
        :process_item_expansion, 
        list_id: list.id, 
        item_id: item.id, 
        text: item.text
      )
    end

    command :replace_item, id: Types::String.present, lines: [Types::String.present] do |list, cmd|
      return unless list.active?

      cmd.payload.lines.each do |line|
        validate_duplicated_item(list, line) do
          event :item_added, id: SecureRandom.uuid, text: line
        end
      end

      event :item_removed, id: cmd.payload.id
    end

    command :update_item_text, id: Types::String.present, text: Types::String.present do |list, cmd|
      return unless list.active?

      item = list.find_item(cmd.payload.id)
      # TODO: raise just brings the workers down and retries on reboot
      # These should really be domain error events
      raise "Item not found with '#{cmd.payload.id}'" unless item
      if item.text != cmd.payload.text
        validate_duplicated_item(list, cmd.payload.text) do
          event :item_text_updated, cmd.payload
        end
      end
    end

    event :item_text_updated, id: String, text: String do |list, evt|
      item = list.find_item(evt.payload.id)
      item.text = evt.payload.text
      list.duplicated_item = nil
      list.paused = false
    end

    event :item_duplicated, id: String do |list, evt|
      item = list.find_item(evt.payload.id)
      list.duplicated_item = item
      list.paused = true
    end

    event :item_added, id: String, text: String do |list, evt|
      list.duplicated_item = nil
      list.paused = false
      list.add_item(evt.payload.to_h)
    end

    command :toggle_item, id: Types::String.present do |list, cmd|
      return unless list.active?

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
      return unless list.active?

      item = list.find_item(cmd.payload.id)
      raise "Item not found with '#{cmd.payload.id}'" unless item
      event :item_dispatched, cmd.payload
    end

    event :item_dispatched, id: String, service: String do |list, evt|
      item = list.find_item(evt.payload.id)
      item.add_service(evt.payload.service)
    end

    command :remove_item, id: Types::String.present do |list, cmd|
      return unless list.active?

      item = list.find_item(cmd.payload.id)
      raise "Item not found with '#{cmd.payload.id}'" unless item
      event :item_removed, id: item.id
    end

    event :item_removed, id: String do |list, evt|
      list.remove_item(evt.payload.id)
    end

    command :archive do |list, cmd|
      return unless list.active?

      event :archived
    end

    event :archived do |list, evt|
      list.status = 'archived'
    end

    command :delete do |list, cmd|
      return unless list.archived?

      event :deleted
    end

    event :deleted do |list, evt|
      list.status = 'deleted'
    end

    command(
      :reorder_items,
      from: Types::Lax::Integer.present, 
      to: Types::Lax::Integer.present
      ) do |list, cmd|
      if list.items[cmd.payload.from] && list.items[cmd.payload.to]
        event :items_reordered, cmd.payload
      end
    end

    event :items_reordered, from: Integer, to: Integer do |list, evt|
      from = evt.payload.from
      to = evt.payload.to
      # Given from and to indices, I want to reorder list.items
      list.items = list.items.dup.tap do |items|
        items.insert(to, items.delete_at(from))
      end
    end

    private

    def validate_duplicated_item(list, text, &)
      previous_item = list.find_item_by_text(text)
      if previous_item
        event :item_duplicated, id: previous_item.id
      else
        yield
      end
    end
  end
end
