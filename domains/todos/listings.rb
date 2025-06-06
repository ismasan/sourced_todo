# frozen_string_literal: true

module Todos
  # A projector
  # Listens to TODO list events
  # and maintains a list of TODO lists as JSON files on disk at ./storage/todo_lists
  class Listings < Sourced::Projector::EventSourced
    DATA_DIR = './storage/todo_lists'

    # This needs work
    # We define an "ephemeral" event to signal the system that the listings have been updated
    # So that the UI can react to it
    module System
      Updated = ::Sourced::Event.define('todos.listings.system.updated')
    end

    # Configure a reactor's time window when fetching events
    consumer do |c|
      # Catch up with events from the beginning of time
      # This is the default
      # Useful for projections that want to rebuild state from scratch
      c.start_from = :beginning

      # Catch up with events produced in the last ~5 seconds
      # Useful for reactors with side effects (ex. send emails)
      # that should not trigger effects for older events
      # ex. when the workers have been down for a while
      # c.start_from = :now

      # Catch up with events produced within a custom time window
      # c.start_from = -> { Time.now - 3600 }
    end

    state do |id|
      {
        id:,
        name: nil,
        seq: 0,
        members: [],
        item_count: 0,
        done_count: 0,
        status: 'active',
        created_at_int: 0,
        udpated_at: nil
      }
    end

    # This block runs in a transaction when handling events
    # Just write a JSON representation of these listings
    sync do |list, _command, events|
      path = File.join(DATA_DIR, "#{list[:id]}.json")

      if list[:status] == 'deleted'
        File.unlink(path) if File.exist?(path)
      else
        FileUtils.mkdir_p(DATA_DIR)
        File.write(path, JSON.pretty_generate(list))
      end
    end

    # Let's give this class a repository interface
    # So that everything about this data is encapsuated here
    def self.all
      Dir[File.join(DATA_DIR, '*.json')].map do |file|
        JSON.parse(File.read(file), symbolize_names: true)
      end.sort_by { |list| list[:created_at_int] }.reverse
    end

    # Emit an ephemeral event every time this projection is updates
    # so that the UI can react to it
    # For now we're publishing on a channel shared by all clients
    # It could also be scoped by the current session, or tenant, or user, or todo-list
    # based on event metadata. ex. events.last.metadata[:tenant_id]
    sync do |list, _command, events|
      Sourced.config.backend.pubsub.publish('system', events.last.follow(System::Updated))
    end

    # Register all events from Todos::List
    # So that before_evolve runs before all TODO events
    evolve_all Todos::List.handled_commands
    evolve_all Todos::List

    before_evolve do |list, event|
      list[:seq] = event.seq
      username = event.metadata[:username]&.downcase
      list[:members] << username if username && !list[:members].include?(username)
      list[:updated_at] = event.created_at
    end

    event Todos::List::Created do |list, event|
      list[:name] = event.payload.name
      list[:created_at_int] = event.created_at.to_i
    end

    event Todos::List::NameUpdated do |list, event|
      list[:name] = event.payload.name
    end

    event Todos::List::ItemAdded do |list, event|
      list[:item_count] += 1
    end

    event Todos::List::ItemRemoved do |list, event|
      list[:item_count] -= 1
    end

    event Todos::List::ItemDone do |list, event|
      list[:done_count] += 1
    end

    event Todos::List::ItemUndone do |list, event|
      list[:done_count] -= 1
    end

    event Todos::List::Archived do |list, event|
      list[:status] = 'archived'
    end

    event Todos::List::Deleted do |list, event|
      list[:status] = 'deleted'
    end
  end
end
