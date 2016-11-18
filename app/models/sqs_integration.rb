class SqsIntegration < ActiveRecord::Base

  validates :queue_url, length: { minimum: 10 }
  validate :starts_with_https
  def starts_with_https
    if queue_url.to_s.split('').first(5).join('') != 'https'
      errors.add(:queue_url, "must begin with https")
    end
  end

  include Rails.application.routes.url_helpers

  def send_notification(change)
    puts "slack_integration#send_notification #{self.queue_url}"

    page_name = change&.after&.page&.name
    text = "#{page_name} changed #{page_change_url(change)}"

    payload = {
      "page_name": page_name,
      "text": text,

      "url": page_change_url(change),
      "event": "update",
      "source": "klaxon",
      "type": "external",
      "eventTS": Time.now.to_i
    }

    SqsNotification.perform(self.queue_url, payload)
    return payload
  end

end