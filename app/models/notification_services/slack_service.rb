class NotificationServices::SlackService < NotificationService
  CHANNEL_NAME_REGEXP = /^#[a-z\d_-]+$/
  LABEL = "slack"
  FIELDS += [
    [:service_url, {
      placeholder: 'Slack Hook URL (https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXX/XXXXXXXXX)',
      label:       'Hook URL'
    }],
    [:room_id, {
      placeholder: '#general',
      label:       'Notification channel',
      hint:        'If empty Errbit will use the default channel for the webook'
    }]
  ]

  # Make room_id optional in case users want to use the default channel
  # setup on Slack when creating the webhook
  def check_params
    if service_url.blank?
      errors.add :service_url, "You must specify your Slack Hook url"
    end

    if room_id.present? && !CHANNEL_NAME_REGEXP.match(room_id)
      errors.add :room_id, "Slack channel name must be lowercase, with no space, special character, or periods."
    end
  end

  def message_for_slack(problem)
    recent = problem.notices.where(:created_at.gte => 5.minutes.ago).count
    message = problem.message.gsub(/\s+/," ").truncate(100)
    app = problem.app.name
    "#{app} - total:#{problem.notices_count}  5min:#{recent}  <#{problem_url(problem)}|#{encode(message)}>"
  end

  def encode(str)
    str.gsub("&", "&amp;")
       .gsub("<", "&lt;")
       .gsub(">", "&gt;")
  end

  def post_payload(problem)
    {
      :text => message_for_slack(problem),
      :mrkdwn => false
    }.to_json
  end

  def create_notification(problem)
    HTTParty.post(
      service_url,
      body:    post_payload(problem),
      headers: {
        'Content-Type' => 'application/json'
      }
    )
  end

  def configured?
    service_url.present?
  end
end
