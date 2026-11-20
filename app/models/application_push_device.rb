# A phone that receives push notifications (action_push_native, ADR 0012). Its owner is the signed-in Session it was
# registered from. An invalid token (app uninstalled…) destroys the device, the gem's default.
class ApplicationPushDevice < ActionPushNative::Device
  validates :token, presence: true, length: { maximum: 4096 }
end
