class Stylesheet < ActiveRecord::Base
  validates_presence_of :contents

  def rebuild!
    self.update(contents: Stylesheet.css)
  end

  def self.build_sheet!
    unless Stylesheet.first
      Stylesheet.create!(contents: Stylesheet.css)
    end
  end

  private
  def self.primary
    Setting.find_by(name: 'main_color').value
  end

  def self.secondary
    Setting.find_by(name: 'secondary_color').value
  end

  def self.primary_light
    self.primary.paint.lighten(10)
  end

  def self.primary_dark
    self.primary.paint.darken(20)
  end

  def self.secondary_light
    self.secondary.paint.lighten(10)
  end

  def self.secondary_dark
    self.secondary.paint.darken(20)
  end

  def self.primary_with_alpha(alpha)
    self.primary.paint.to_rgb.insert(3, 'a').insert(-2, ", #{alpha}")
  end

  def self.css
    ".bg-red { background-color: #{Stylesheet.primary}; }
     .bg-red-dark { background-color: #{Stylesheet.primary}; }
     #nav .nav { background-color: #{Stylesheet.primary}; }
     #nav .nav > li > a { color: white; }
     #nav .nav > li > a:hover, #nav .nav > li > a:focus { background-color: #{Stylesheet.primary_light}; }
     #nav .nav > li > a.active { border-left: 3px solid #{Stylesheet.primary_dark}; background-color: #{Stylesheet.primary_light}; }
     #nav .nav > li > a.active { border-left: 3px solid #{Stylesheet.primary_dark}; background-color: #{Stylesheet.primary_light}; }
     .btn-theme { background-color: #{Stylesheet.primary}; color: white; }
     .btn-theme:active, .btn-theme:hover { background-color: #{Stylesheet.primary_dark}; }
     .label-theme { background-color: #{Stylesheet.primary} }
     .btn-link { color: #{Stylesheet.primary} !important; }
     .btn-link:hover { color: #{Stylesheet.primary_dark} !important; }
     a { color: #{Stylesheet.primary}; }
     a:hover, a:focus { color: #{Stylesheet.primary_dark}; }
     h2, h3, h5 { color: #{Stylesheet.primary}; }
     h5:after { background-color: #{Stylesheet.primary}; }
     .bg-yellow { background-color: #{Stylesheet.secondary} !important; }
     .event:hover { background-color: #{Stylesheet.primary}; }
     .widget h3 { color: #{Stylesheet.primary}; }
     .modal-header h1, .custom-invoice .modal-header h1 { color: #{Stylesheet.primary}; }
     .block-link:hover, .fc-toolbar .fc-button:hover, .fc-toolbar .fc-button:active, .fc-toolbar .fc-button.fc-state-active { background-color: #{Stylesheet.secondary}; }
     .carousel-control:hover, .carousel-control:focus, .carousel-caption .title a:hover { color: #{Stylesheet.secondary}; }
     .well.well-warning { border-color: #{Stylesheet.secondary};  background-color: #{Stylesheet.secondary};  }
     .text-yellow { color: #{Stylesheet.secondary} !important; }
     .red { color: #{Stylesheet.primary} !important; }
     .btn-warning, .editable-buttons button[type=submit].btn-primary { background-color: #{Stylesheet.secondary} !important; border-color: #{Stylesheet.secondary} !important; }
     .btn-warning:hover, .editable-buttons button[type=submit].btn-primary:hover, .btn-warning:focus, .editable-buttons button[type=submit].btn-primary:focus, .btn-warning.focus, .editable-buttons button.focus[type=submit].btn-primary, .btn-warning:active, .editable-buttons button[type=submit].btn-primary:active, .btn-warning.active, .editable-buttons button.active[type=submit].btn-primary, .open > .btn-warning.dropdown-toggle, .editable-buttons .open > button.dropdown-toggle[type=submit].btn-primary { background-color: #{Stylesheet.secondary_dark} !important; border-color: #{Stylesheet.secondary_dark} !important; }
     .btn-warning-full { border-color: #{Stylesheet.secondary}; background-color: #{Stylesheet.secondary}; }
     .heading .heading-btn a:hover { background-color: #{Stylesheet.secondary}; }
     .pricing-panel .content .wrap { border-color: #{Stylesheet.secondary}; }
     .pricing-panel .cta-button .btn:hover, .pricing-panel .cta-button .custom-invoice .modal-body .elements li:hover, .custom-invoice .modal-body .elements .pricing-panel .cta-button li:hover { background-color: #{Stylesheet.secondary} !important; }
     a.label:hover, .form-control.form-control-ui-select .select2-choices a.select2-search-choice:hover, a.label:focus, .form-control.form-control-ui-select .select2-choices a.select2-search-choice:focus { color: #{Stylesheet.primary}; }
     .about-picture { background: linear-gradient( rgba(255,255,255,0.12), rgba(255,255,255,0.13) ), linear-gradient( #{Stylesheet.primary_with_alpha(0.78)}, #{Stylesheet.primary_with_alpha(0.82)} ), url('/about-fablab.jpg') no-repeat; }
     .social-icons > div:hover { background-color: #{Stylesheet.secondary}; }
     .profile-top { background: linear-gradient( rgba(255,255,255,0.12), rgba(255,255,255,0.13) ), linear-gradient(#{Stylesheet.primary_with_alpha(0.78)}, #{Stylesheet.primary_with_alpha(0.82)} ), url('#{CustomAsset.get_url('profile-image-file') || '/about-fablab.jpg'}') no-repeat; }
     .profile-top .social-links a:hover { background-color: #{Stylesheet.secondary} !important; border-color: #{Stylesheet.secondary} !important; }"

  end
end
