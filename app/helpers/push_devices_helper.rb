# The element of the "push" bridge component (push_controller.js, ADR 0012): it registers the phone of this session
# for push notifications. It carries the fingerprints of the session's phones, so that the page posts a token only
# when it is new (a new session, a token renewed by Firebase), not on every page.
module PushDevicesHelper
  def push_registration_tag(name = :div, **options, &)
    data = {
      controller: "bridge--push",
      bridge__push_fingerprints_value: push_token_fingerprints.to_json,
      bridge__push_url_value: push_devices_path
    }
    # Empty or with a block: the attributes always go as attributes, never as the content.
    content_tag(name, nil, options.merge(data: data.merge(options.fetch(:data, {}))), &)
  end

  def push_token_fingerprints
    Current.session.push_devices.pluck(:token).map { |token| Digest::SHA256.hexdigest(token) }
  end
end
