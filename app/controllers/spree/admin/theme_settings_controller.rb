module Spree
  module Admin
    class ThemeSettingsController < Spree::Admin::BaseController
      include Spree::Backend::Callbacks

      def edit
      end

      def update
        redirect_to edit_admin_theme_settings_path
      end

    end
  end
end