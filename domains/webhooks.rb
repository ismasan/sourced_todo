require 'lib/slack'

module Webhooks
  # This actor reacts to events emitted by Todos::ListActor
  # When a Todo item is marked as `done`, it will post a message to Slack
  # You need to setup yout .env with a SLACK_WEBHOOK_URL
  # This Actor projects its own state from the events it receives
  # to gather the information it needs to post to Slack
  # until it received a Todos::ListActor::ItemDone event
  # It then reacts to that event by posting a message to Slack
  # When it's done, it dispatches a Todos::ListActor::NotifyDispatched to Todos::ListActor
  class SlackDispatcher < Sourced::Actor
    state do |id|
      { id:, items: {} }
    end

    event Todos::ListActor::ItemAdded do |state, evt|
      state[:items][evt.payload.id] = evt.payload.to_h
    end

    event Todos::ListActor::ItemTextUpdated do |state, evt|
      state[:items][evt.payload.id][:text] = evt.payload.text
    end

    event Todos::ListActor::ItemDone do |state, evt|
      state[:items][evt.payload.id][:done] ||= 0
      state[:items][evt.payload.id][:done] += 1
      state[:items][evt.payload.id][:last_done] = evt.created_at
    end

    react_with_state Todos::ListActor[:item_done] do |state, evt|
      item = state[:items][evt.payload.id]
      if item[:done] > 1 && (Time.now - item[:last_done]) < 60
        # Do we want to post a different message to Slack?
        puts "Item #{evt.payload.id} has been done #{item[:done]} times"
      end

      # Lets pretend this is really slow
      sleep 3
      # TODO: error handling
      # Here we have some options:
      # * raise an exception to have the workers retry (indefinitely)
      # * keep count of retries and stop after N retries
      # * send a different command to the ListActor to notify the error
      Slack.post(text: "Item '#{item[:text]}' has been done")

      command Todos::ListActor::NotifyDispatched, id: evt.payload.id, service: 'Slack'
    end
  end
end
