class NotificationServices::SlackService < NotificationService
  Label = "slack"
  Fields += [
    [:service_url, {
      :placeholder => 'Slack Hook URL (https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXX/XXXXXXXXX)',
      :label => 'Hook URL'
    }]
  ]

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, "You must specify your Slack Hook url."
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
    HTTParty.post(service_url, :body => post_payload(problem), :headers => { 'Content-Type' => 'application/json' })
  end

  def configured?
    service_url.present?
  end
end
