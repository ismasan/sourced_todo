# frozen_string_literal: true

# {
#   "id": "chatcmpl-B5D7P4k46OCuvdswIzxFZltHzyYxm",
#   "object": "chat.completion",
#   "created": 1740581767,
#   "model": "gpt-4o-2024-08-06",
#   "choices": [
#     {
#       "index": 0,
#       "message": {
#         "role": "assistant",
#         "content": "[\n  \"Buy two dozen eggs.\",\n  \"Buy milk.\",\n  \"Consider buying butter.\"\n]",
#         "refusal": null
#       },
#       "logprobs": null,
#       "finish_reason": "stop"
#     }
#   ],
#   "usage": {
#     "prompt_tokens": 74,
#     "completion_tokens": 21,
#     "total_tokens": 95,
#     "prompt_tokens_details": {
#       "cached_tokens": 0,
#       "audio_tokens": 0
#     },
#     "completion_tokens_details": {
#       "reasoning_tokens": 0,
#       "audio_tokens": 0,
#       "accepted_prediction_tokens": 0,
#       "rejected_prediction_tokens": 0
#     }
#   },
#   "service_tier": "default",
#   "system_fingerprint": "fp_f9f4fb6dbf"
# }
require 'net/http'
require 'uri'
require 'json'

# Send a prompt to OpenAI's API and get a list of TODO items
# @example
#
#  items = OpenAI.new.todos_for("Buy two dozen eggs, buy milk, consider buying butter")
class OpenAI
  API_KEY = ENV.fetch('OPENAI_API_KEY')
  SYSTEM_PROMPT = %(You are an assistant that helps turning long-form text into actionable todo items. Identify and extract the action items from the following text, and structure them as a JSON array of TODO items as text. Only return the JSON array and nothing more. Remove any prefixes and line breaks. For example ["buy eggs", "buy milk"])
  URL = 'https://api.openai.com/v1/chat/completions'

  def initialize(api_key: API_KEY)
    @api_key = api_key
    @uri = URI(URL)
  end

  def todos_for(prompt)
    http = Net::HTTP.new(@uri.host, @uri.port)
    http.use_ssl = true

    payload = {
      model: 'gpt-4o',
      store: true,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { 
          role: 'user', 
          content: [
            { type: 'text', text: prompt }
          ]
        }
        # { role: 'user', content: prompt }
      ]
    }

    request = Net::HTTP::Post.new(@uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@api_key}"
    request.body = JSON.dump(payload)

    resp = http.request(request)
    raise "OpenAI request failed: #{resp.code} #{resp.body}" unless resp.is_a?(Net::HTTPSuccess)

    data = JSON.parse(resp.body)
    return [] unless data['choices'].any?

    json = data['choices'].first.dig('message', 'content')

    JSON.parse(json)
  end
end
