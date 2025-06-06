# frozen_string_literal: true

require 'sinatra/base'
require 'datastar'
require 'sourced/ui'
# require_relative 'domains/carts'

class App < Sinatra::Base
  helpers Phlex::Sinatra

  enable :sessions
  enable :method_override
  set :session_secret, ENV.fetch('SESSION_SECRET')
  # set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }

  User = Data.define(:username)

  helpers do
    def logged_in?
      !!session[:username]
    end

    def current_user
      @current_user ||= User.new(username: session[:username])
    end

    def command_context
      @command_context ||= Sourced::CommandContext.new(
        stream_id: SecureRandom.uuid,
        metadata: { 
          producer: 'UI',
          username: current_user&.username
        }
      )
    end

    def datastar
      @datastar ||= Datastar
        .new(request:, response:, view_context: self, heartbeat: 0.4)
                    .on_error do |err|
        puts "Datastar error: #{err}"
        puts err.backtrace.join("\n")
      end
    end
  end

  get '/?' do
    if logged_in?
      phlex Pages::HomePage.new(lists: Todos::Listings.all, layout: true)
    else
      phlex Pages::LoginPage.new
    end
  end

  post '/login/?' do
    form = Types::LoginForm.resolve(params)
    if form.valid?
      session[:username] = form.value[:username]
      redirect '/'
    else
      phlex Pages::LoginPage.new(
        params: form.value,
        errors: form.errors
      )
    end
  end

  get '/logout/?' do
    session.delete :username
    redirect '/'
  end

  get '/todo-lists/:id/?' do |id|
    todo_list = Todos::List.load(id)
    phlex Pages::TodoListPage.new(
      todo_list: todo_list.state, 
      events: todo_list.events,
      layout: true
    )
  end

  # Load a todo list up to a given sequence number
  # Ex. /todo-lists/important-things/34
  get '/todo-lists/:id/:upto?' do
    interactive = false
    upto = Types::Lax::Integer.parse(params[:upto])
    todo_list = Todos::List.load(params[:id], upto:)
    # If this is an SSE request, stream the view back to to the browser
    # If a normal page load, render normally with layout
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

  post '/commands/:list_id/reorder-items' do |list_id|
    cmd = command_context.build(
      Todos::List::ReorderItems,
      stream_id: list_id,
      payload: {
        from: datastar.signals['from'],
        to: datastar.signals['to']
      }
    )

    raise 'Invalid command' unless cmd.valid?
    Console.info cmd.valid?
    Sourced.schedule_commands([cmd])
    204
  end

  post '/commands/?' do
    # Bit hacky, but I want a generic way to validate
    # all commands and send errors back to the UI
    # Here I'm relying on the Sourced::UI::Components::Command component
    # rendering input fields by a specific convention
    # and sending a [command][_cid] generated ID
    # If invalid, I send back error message elements targeting those specific IDs on the page
    req_id = request.env['cf-request-id'] || SecureRandom.uuid
    cmd = command_context.build(params[:command].to_h.merge(id: req_id))
    # Console.info cmd.inspect

    Console.info "cf-request-id: #{req_id}"
    # Console.info cmd.inspect

    Sourced::UI.streaming_command_errors(cmd, datastar) do |cmd|
      Sourced.schedule_commands([cmd])
      halt 204
    end
  end

  get '/updates/?' do
    # Sourced::Ui.serve(request:, response:, view_context: self)

    # TODO: here we're listening on a channel
    # sharred by all clients
    # In reality we should scope by the current session, or tenant, or user, or todo-list
    # TODO: PG LISTEN allows subsribing to multiple channels
    # ie pubsub.subscribe(['system'], ['tenant-1'])
    # This could be beneficial
    # TODO: the browswer can disconnect (by default Datastar disconnects when the browser tab is not active)
    # Here we should re-render on reconnect, but NOT on page load.
    channel = Sourced.config.backend.pubsub.subscribe('system')

    datastar.on_connect do |*args|
      # Here we should keep track of whether 
      # this is an initial page load, or a reconnect.
      # and re-render if the latter.
      puts 'client connect'
    end
    datastar.on_client_disconnect do |*args|
      puts 'client disconnect'
      channel.stop
    end
    datastar.on_server_disconnect do |*args|
      puts 'server disconnect'
      channel.stop
    end
    datastar.on_error do |ex|
      puts "ERROR #{ex}"
      channel.stop
    end

    datastar.stream do |sse|
      channel.start do |evt, channel|
        case evt
        when Todos::List::System::Updated
          if sse.signals['page_key'] == 'Pages::TodoListPage' && sse.signals['page_id'] == evt.stream_id
            todo_list = Todos::List.load(evt.stream_id)
            sse.merge_fragments Pages::TodoListPage.new(
              todo_list: todo_list.state,
              events: todo_list.history,
            )
            sse.execute_script <<-JS
              document.dispatchEvent(new CustomEvent('OrderedListLoaded'))
            JS
          end
        when Todos::Listings::System::Updated
          if sse.signals['page_key'] == 'Pages::HomePage'
            sse.merge_fragments Pages::HomePage.new(lists: Todos::Listings.all)
          end
        else
          puts "Unknown event: #{evt}"
        end
      end
    end
  end
end

trap('INT') do
  puts('Closing!')
  sleep 1
  puts('Byebye!')
  exit
end
