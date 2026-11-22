# Creates the API token for the admin user from the API_TOKEN variable, so an agent can call the API with no UI step.
# Idempotent: a redeploy with the same API_TOKEN finds the token it stored and does nothing.
plain = ENV.fetch("API_TOKEN")
abort("API_TOKEN must be at least 32 characters") if plain.length < 32
admin = User.not_builtin.admin.find_by(login: "admin") || User.not_builtin.admin.order(:id).first
abort("no admin user to attach the API token to") unless admin
if Token::API.find_by_plaintext_value(plain)
  puts "[railway] api token already present"
else
  Token::API.create!(user: admin, value: Token::API.hash_function(plain), token_name: "railway")
  puts "[railway] api token created for #{admin.login}"
end
