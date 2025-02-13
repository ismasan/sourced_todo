  # A projector
  # "reacts" to events registered with .evolve
class Listings < Sourced::Projector::EventSourced
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
    path = "./storage/todo_lists/#{list[:id]}.json"

    if list[:status] == 'deleted'
      File.unlink(path) if File.exist?(path)
    else
      FileUtils.mkdir_p('storage/todo_lists')
      File.write(path, JSON.pretty_generate(list))
    end
  end

  sync do |list, _command, events|
    Sourced.config.backend.pubsub.publish('system', events.last.follow(System::Updated))
  end

  # Register all events from Todos::ListActor
  # So that before_evolve runs before all TODO events
  evolve_all Todos::ListActor.handled_commands
  evolve_all Todos::ListActor

  before_evolve do |list, event|
    list[:seq] = event.seq
    username = event.metadata[:username]&.downcase
    list[:members] << username if username && !list[:members].include?(username)
    list[:updated_at] = event.created_at
  end

  event Todos::ListActor::Created do |list, event|
    list[:name] = event.payload.name
    list[:created_at_int] = event.created_at.to_i
  end

  event Todos::ListActor::NameUpdated do |list, event|
    list[:name] = event.payload.name
  end

  event Todos::ListActor::ItemAdded do |list, event|
    list[:item_count] += 1
  end

  event Todos::ListActor::ItemRemoved do |list, event|
    list[:item_count] -= 1
  end

  event Todos::ListActor::ItemDone do |list, event|
    list[:done_count] += 1
  end

  event Todos::ListActor::ItemUndone do |list, event|
    list[:done_count] -= 1
  end

  event Todos::ListActor::Archived do |list, event|
    list[:status] = 'archived'
  end

  event Todos::ListActor::Deleted do |list, event|
    list[:status] = 'deleted'
  end
end
