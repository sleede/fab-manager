# frozen_string_literal: true

# Stylesheet is a cached CSS file that allows to easily customize the interface of Fab-manager with some configurable colors and
# a picture for the background of the user's profile.
# There's only one stylesheet record in the database, which is updated on each colour change.
class Stylesheet < ApplicationRecord

  # brightness limits to change the font color to black or white
  BRIGHTNESS_HIGH_LIMIT = 160
  BRIGHTNESS_LOW_LIMIT = 40

  validates_presence_of :contents

  ## ===== COMMON =====

  def rebuild!
    if Stylesheet.primary && Stylesheet.secondary && name == 'theme'
      update(contents: Stylesheet.css)
    elsif name == 'home_page'
      update(contents: Stylesheet.home_page_css)
    end
  end

  ## ===== THEME =====

  def self.build_theme!
    return unless Stylesheet.primary && Stylesheet.secondary

    if Stylesheet.theme
      Stylesheet.theme.rebuild!
    else
      Stylesheet.create!(contents: Stylesheet.css, name: 'theme')
    end
  end

  def self.primary
    Setting.find_by(name: 'main_color')&.value
  end

  def self.secondary
    Setting.find_by(name: 'secondary_color')&.value
  end

  def self.primary_light
    Stylesheet.primary.paint.lighten(10)
  end

  def self.primary_dark
    Stylesheet.primary.paint.darken(20)
  end

  def self.secondary_light
    Stylesheet.secondary.paint.lighten(10)
  end

  def self.secondary_dark
    Stylesheet.secondary.paint.darken(20)
  end

  def self.primary_with_alpha(alpha)
    Stylesheet.primary.paint.to_rgb.insert(3, 'a').insert(-2, ", #{alpha}")
  end

  def self.theme
    Stylesheet.find_by(name: 'theme')
  end

  def self.primary_text_color
    Stylesheet.primary.paint.brightness >= BRIGHTNESS_HIGH_LIMIT ? 'black' : 'white'
  end

  def self.primary_decoration_color
    Stylesheet.primary.paint.brightness <= BRIGHTNESS_LOW_LIMIT ? 'white' : 'black'
  end

  def self.secondary_text_color
    Stylesheet.secondary.paint.brightness <= BRIGHTNESS_LOW_LIMIT ? 'white' : 'black'
  end

  def self.css # rubocop:disable Metrics/AbcSize
    <<~CSS
      .bg-red { background-color: #{Stylesheet.primary}; }
      .bg-red-dark { background-color: #{Stylesheet.primary}; }
      #nav .nav { background-color: #{Stylesheet.primary}; }
      #nav .nav > li > a { color: #{Stylesheet.primary_text_color}; }
      #nav .nav > li > a:hover, #nav .nav > li > a:focus { background-color: #{Stylesheet.primary_light}; color: #{Stylesheet.primary_text_color}; }
      #nav .nav > li > a.active { border-left: 3px solid #{Stylesheet.primary_dark}; background-color: #{Stylesheet.primary_light}; color: #{Stylesheet.primary_text_color}; }
      .nav-primary ul.nav > li.menu-spacer { background: linear-gradient(45deg, #{Stylesheet.primary_decoration_color}, transparent); }
      .nav-primary .text-bordeau { color: #{Stylesheet.primary_decoration_color}; }
      .btn-theme { background-color: #{Stylesheet.primary}; color: #{Stylesheet.primary_text_color}; }
      .btn-theme:active, .btn-theme:hover { background-color: #{Stylesheet.primary_dark}; color: #{Stylesheet.primary_text_color}; }
      .label-theme { background-color: #{Stylesheet.primary}; color: #{Stylesheet.primary_text_color}; }
      .btn-link { color: #{Stylesheet.primary} !important; }
      .btn-link:hover { color: #{Stylesheet.primary_dark} !important; }
      a { color: #{Stylesheet.primary}; }
      a:hover, a:focus { color: #{Stylesheet.primary_dark}; }
      h2, h3, h5 { color: #{Stylesheet.primary}; }
      h5:after { background-color: #{Stylesheet.primary}; }
      .bg-yellow { background-color: #{Stylesheet.secondary} !important; color: #{Stylesheet.secondary_text_color}; }
      .event:hover { background-color: #{Stylesheet.primary}; color: #{Stylesheet.secondary_text_color}; }
      .widget h3 { color: #{Stylesheet.primary}; }
      .modal-header h1, .custom-invoice .modal-header h1 { color: #{Stylesheet.primary}; }
      .block-link:hover, .fc-toolbar .fc-button:hover, .fc-toolbar .fc-button:active, .fc-toolbar .fc-button.fc-state-active { background-color: #{Stylesheet.secondary}; color: #{Stylesheet.secondary_text_color} !important; }
      .block-link:hover .user-name { color: #{Stylesheet.secondary_text_color} !important; }
      .carousel-control:hover, .carousel-control:focus, .carousel-caption .title a:hover { color: #{Stylesheet.secondary}; }
      .well.well-warning { border-color: #{Stylesheet.secondary};  background-color: #{Stylesheet.secondary}; color: #{Stylesheet.secondary_text_color};  }
      .text-yellow { color: #{Stylesheet.secondary} !important; }
      .red { color: #{Stylesheet.primary} !important; }
      .btn-warning, .editable-buttons button[type=submit].btn-primary { background-color: #{Stylesheet.secondary} !important; border-color: #{Stylesheet.secondary} !important; color: #{Stylesheet.secondary_text_color}; }
      .btn-warning:hover, .editable-buttons button[type=submit].btn-primary:hover, .btn-warning:focus, .editable-buttons button[type=submit].btn-primary:focus, .btn-warning.focus, .editable-buttons button.focus[type=submit].btn-primary, .btn-warning:active, .editable-buttons button[type=submit].btn-primary:active, .btn-warning.active, .editable-buttons button.active[type=submit].btn-primary, .open > .btn-warning.dropdown-toggle, .editable-buttons .open > button.dropdown-toggle[type=submit].btn-primary { background-color: #{Stylesheet.secondary_dark} !important; border-color: #{Stylesheet.secondary_dark} !important; color: #{Stylesheet.secondary_text_color}; }
      .btn-warning-full { border-color: #{Stylesheet.secondary}; background-color: #{Stylesheet.secondary}; color: #{Stylesheet.secondary_text_color} !important; }
      .heading .heading-btn a:hover { background-color: #{Stylesheet.secondary}; color: #{Stylesheet.secondary_text_color}; }
      .pricing-panel .content .wrap { border-color: #{Stylesheet.secondary}; }
      .pricing-panel .cta-button .btn:hover, .pricing-panel .cta-button .custom-invoice .modal-body .elements li:hover, .custom-invoice .modal-body .elements .pricing-panel .cta-button li:hover { background-color: #{Stylesheet.secondary} !important; color: #{Stylesheet.secondary_text_color}; }
      a.label:hover, .form-control.form-control-ui-select .select2-choices a.select2-search-choice:hover, a.label:focus, .form-control.form-control-ui-select .select2-choices a.select2-search-choice:focus { color: #{Stylesheet.primary}; }
      .about-picture { background: linear-gradient( rgba(255,255,255,0.12), rgba(255,255,255,0.13) ), linear-gradient( #{Stylesheet.primary_with_alpha(0.78)}, #{Stylesheet.primary_with_alpha(0.82)} ), url('/about-fablab.jpg') no-repeat; }
      .social-icons > div:hover { background-color: #{Stylesheet.secondary}; color: #{Stylesheet.secondary_text_color}; }
      .profile-top { background: linear-gradient( rgba(255,255,255,0.12), rgba(255,255,255,0.13) ), linear-gradient(#{Stylesheet.primary_with_alpha(0.78)}, #{Stylesheet.primary_with_alpha(0.82)} ), url('#{CustomAsset.get_url('profile-image-file') || '/about-fablab.jpg'}') no-repeat; }
      .profile-top .social-links a:hover { background-color: #{Stylesheet.secondary} !important; border-color: #{Stylesheet.secondary} !important; color: #{Stylesheet.secondary_text_color}; }
      section#cookies-modal div.cookies-consent .cookies-actions button.accept { background-color: #{Stylesheet.secondary}; color: #{Stylesheet.secondary_text_color}; }
    CSS
  end

  ## ===== HOME PAGE =====

  def self.home_style
    style = Setting.find_by(name: 'home_css')&.value
    ".home-page { #{style} }"
  end

  def self.build_home!
    if Stylesheet.home_page
      Stylesheet.home_page.rebuild!
    else
      Stylesheet.create!(contents: Stylesheet.home_page_css, name: 'home_page')
    end
  end

  def self.home_page
    Stylesheet.find_by(name: 'home_page')
  end

  def self.home_page_css
    engine = Sass::Engine.new(home_style, syntax: :scss)
    engine.render.presence || '.home-page {}'
  end
end
