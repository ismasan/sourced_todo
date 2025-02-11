require 'lib/slack'

module Webhooks
  class Dispatcher < Sourced::Actor
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
      Slack.post(text: "Item '#{item[:text]}' has been done")

      command Todos::ListActor::NotifyDispatched, id: evt.payload.id, service: 'Slack'
    end
  end
end
