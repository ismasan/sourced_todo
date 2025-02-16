# frozen_string_literal: true

require 'lib/slack'

module Todos
  # This actor reacts to events emitted by Todos::List
  # When a Todo item is marked as `done`, it will post a message to Slack
  # You need to setup yout .env with a SLACK_WEBHOOK_URL
  # This Actor projects its own state from the events it receives
  # to gather the information it needs to post to Slack
  # until it received a Todos::List::ItemDone event
  # It then reacts to that event by posting a message to Slack
  # When it's done, it dispatches a Todos::List::NotifyDispatched to Todos::List
  class SlackDispatcher < Sourced::Actor
    state do |id|
      { id:, name: nil, items: {} }
    end

    event Todos::List::Created do |state, evt|
      state[:name] = evt.payload.name
    end

    event Todos::List::ItemAdded do |state, evt|
      state[:items][evt.payload.id] = evt.payload.to_h
    end

    event Todos::List::ItemTextUpdated do |state, evt|
      state[:items][evt.payload.id][:text] = evt.payload.text
    end

    # Keep track of what the item text was during the last
    # two consecutive `done` events
    # So that we don't post the same message to Slack twice
    # This is a fairly arbitrary rule, but it's just an example
    # of how events allow us to implement "history sensitive" logic
    event Todos::List::ItemDone do |state, evt|
      item = state[:items][evt.payload.id]
      item[:dones] ||= []
      item[:dones] << item[:text]
      item[:dones].shift if item[:dones].size > 2
      item[:member] = evt.metadata[:username]
    end

    reaction_with_state Todos::List[:item_done] do |state, evt|
      item = state[:items][evt.payload.id]
      if item[:dones].size == 2 && (item[:dones].last == item[:dones].first)
        # Do we want to post a different message to Slack?
        puts "Item #{evt.payload.id} has been done recently already"
      else
        # Lets pretend this is really slow
        sleep 3
        # TODO: error handling
        # Here we have some options:
        # * raise an exception to have the workers retry (indefinitely)
        # * keep count of retries and stop after N retries
        # * send a different command to the List to notify the error
        Slack.post(texts: [
          "Item '#{item[:text]}' has been done by <@#{item[:member]}>",
          "list: <http://localhost:9292/todo-lists/#{state[:id]}|#{state[:name]}>"
        ])

        command Todos::List::NotifyDispatched, id: evt.payload.id, service: 'Slack'
      end
    end
  end
end
