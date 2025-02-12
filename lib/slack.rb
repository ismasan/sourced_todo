require 'net/http'
require 'uri'
require 'json'

class Slack
  URL = ENV.fetch('SLACK_WEBHOOK_URL')

  def self.post(...)
    new.post(...)
  end

  def initialize(url: URL)
    @url = url
  end

  def post(texts: [])
    uri = URI(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    payload = {
      text: texts.first,
      blocks: texts.map do |text|
        {
          type: 'section',
          text: { type: 'mrkdwn', text: text }
        }
      end
    }

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = JSON.dump(payload)

    http.request(request)
  end
end
