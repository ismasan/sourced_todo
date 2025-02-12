# frozen_string_literal: true

require 'sinatra/base'
require 'datastar'
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
                    .new(request:, response:, view_context: self)
                    .on_error do |err|
        puts "Datastar error: #{err}"
        puts err.backtrace.join("\n")
      end
    end
  end

  get '/?' do
    if logged_in?
      lists = Dir['./storage/todo_lists/*.json'].map do |file|
        JSON.parse(File.read(file), symbolize_names: true)
      end.sort_by { |list| list[:created_at_int] }.reverse

      phlex Pages::HomePage.new(lists:, layout: true)
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
    todo_list = Todos::ListActor.load(id)
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

  post '/commands/?' do
    cmd = command_context.build(params[:command].to_h)
    Console.info cmd.inspect
    # TODO: if command is invalid
    # notify the UI
    raise cmd.errors.inspect unless cmd.valid?

    actor, events = Sourced::Router.handle_command(cmd)
    # Here we can run the command and render the list
    # back to the UI, or we can return a 204
    # and let the SSE stream pick up the event and update the UI
    #
    # datastar.stream do |sse|
    #   sse.merge_fragments Components::TodoList.new(todo_list: actor.state)
    #   sse.merge_fragments(Components::EventList.new(
    #     events: actor.events,
    #     href_prefix: 'todo-lists'
    #   ))
    # end
    halt 204
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
    # TODO: here we're listening on a channel
    # sharred by all clients
    # In reality we should scope by the current session, or tenant, or user, or todo-list
    channel = Sourced.config.backend.pubsub.subscribe('system')

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

    # Hack: need to send a hearbeat
    # for the Ruby SDK to trigger #on_client_disconnect
    # if browser disconnected
    # TODO: fix SDK to detect closed connection event with one #stream block
    datastar.stream do |sse|
      while true
        sleep 1
        sse.merge_signals(hb: true)
      end
    end

    datastar.stream do |sse|
      channel.start do |evt, channel|
        case evt
        when Todos::ListActor::System::Updated
          if sse.signals['page_key'] == 'Pages::TodoListPage' && sse.signals['page_id'] == evt.stream_id
            todo_list = Todos::ListActor.load(evt.stream_id)
            sse.merge_fragments Pages::TodoListPage.new(
              todo_list: todo_list.state,
              events: todo_list.history,
            )
          end
        when Listings::System::Updated
          if sse.signals['page_key'] == 'Pages::HomePage'
            lists = Dir['./storage/todo_lists/*.json'].map do |file|
              JSON.parse(File.read(file), symbolize_names: true)
            end.sort_by { |list| list[:created_at_int] }.reverse

            sse.merge_fragments Pages::HomePage.new(lists:)
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
