# frozen_string_literal: true

class Settings < Settingslogic
  source Rails.root.join('config', 'application.yml').to_path
  namespace Rails.env
end
