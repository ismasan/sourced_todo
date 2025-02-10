# frozen_string_literal: true

require 'sinatra/base'
require 'datastar'
# require_relative 'domains/carts'

class App < Sinatra::Base
  enable :sessions
  enable :method_override
  set :session_secret, ENV.fetch('SESSION_SECRET')
  # set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }

  DEMO_TODO_LIST = 'demo-todo-list'

  helpers do
    def todo_list_id
      DEMO_TODO_LIST
    end

    def command_context
      @command_context ||= Sourced::CommandContext.new(
        stream_id: todo_list_id,
        metadata: { producer: 'UI' }
      )
    end

    def datastar
      @datastar ||= Datastar
                    .new(request:, response:, view_context: self)
                    .on_error do |err|
        puts "Datastar error: #{err}"
        puts err.backtrace.join("\n")
      end
    end
  end

  get '/?' do
    todo_list = Todos::ListActor.load(todo_list_id)
    phlex Pages::TodoListPage.new(
      todo_list: todo_list.state, 
      events: todo_list.events,
      layout: true
    )
  end

  get '/todo-lists/:id/:upto?' do
    interactive = false
    upto = Types::Lax::Integer.parse(params[:upto])
    todo_list = Todos::ListActor.load(params[:id], upto:)
    if datastar.sse?
      datastar.stream do |sse|
        sse.execute_script <<-JS
          history.replaceState({}, '', '/todo-lists/#{todo_list.id}/#{upto}')
        JS
        sse.merge_fragments Pages::TodoListPage.new(
          todo_list: todo_list.state,
          events: todo_list.history,
          seq: upto,
          interactive:
        )
      end
    else
      phlex Pages::TodoListPage.new(
        todo_list: todo_list.state, 
        events: todo_list.history,
        seq: upto,
        interactive:,
        layout: true
      )
    end
  end

  post '/commands/?' do
    cmd = command_context.build(params[:command].to_h)
    raise cmd.errors.inspect unless cmd.valid?

    actor, events = Sourced::Router.handle_command(cmd)
    datastar.stream do |sse|
      sse.merge_fragments Components::TodoList.new(todo_list: actor.state)
      sse.merge_fragments(Components::EventList.new(
        events: actor.events,
        show_commands: actor.state.show_commands,
        href_prefix: 'todo-lists'
      ))
    end
    # halt 202
  end

  get '/events/:event_id/correlation' do |event_id|
    events = Sourced.config.backend.read_correlation_batch(event_id)
    datastar.stream do |sse|
      sse.merge_fragments Components::Modal.new(
        title: 'Event correlation',
        content: Components::EventsTree.new(events:, highlighted: event_id)
      )
      sse.merge_signals modal: true
    end
  end

  get '/updates/?' do
  end
end
