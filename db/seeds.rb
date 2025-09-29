# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create a default user for development
User.find_or_create_by!(email: "admin@devinator.local") do |user|
  user.name = "Admin User"
  user.role = "admin"
  user.password_hash = "placeholder_hash"
  user.is_active = true
  user.jira_credentials = { api_token: "placeholder", server_url: "https://company.atlassian.net" }.to_json
  user.preferences = { theme: "light", notifications: true }.to_json
end

puts "✅ Created default admin user (admin@devinator.local)"
