# Registers the phone of the signed-in session for push notifications. Called by the Android app (bridge component)
# with the Firebase token of the phone. A token already known moves to this session: one phone, one owner.
class PushDevicesController < ApplicationController
  def create
    device = ApplicationPushDevice.new(owner: Current.session, platform: :google, **device_params)
    authorize device
    return head(:unprocessable_content) unless device.valid?

    ApplicationPushDevice.upsert(
      device.attributes.slice("token", "name", "platform", "owner_type", "owner_id"),
      unique_by: :token
    )
    head :created
  end

  private

  def device_params
    params.expect(push_device: [ :token, :name ])
  end
end
