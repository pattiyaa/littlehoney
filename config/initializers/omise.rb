GATEWAY = ActiveMerchant::Billing::OmiseGateway.new(
  public_key: "pkey_test_5767zvemnmix271zxc0",
  secret_key: Rails.application.secrets.omise_secret_key
)