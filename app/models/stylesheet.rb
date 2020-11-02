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
      update(contents: Stylesheet.theme_css)
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
      Stylesheet.create!(contents: Stylesheet.theme_css, name: 'theme')
    end
  end

  def self.primary
    Setting.get('main_color')
  end

  def self.secondary
    Setting.get('secondary_color')
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

  def self.theme_css
    erb_files = Dir['app/themes/casemate/**/*.scss.erb']
    scss_files = Dir['app/themes/casemate/**/*.scss']

    templates = ''
    erb_files.each { |erb_file| templates += ERB.new(File.read(erb_file)).result }
    scss_files.each { |scss_file| templates += File.read(scss_file) }

    engine = SassC::Engine.new(templates, style: :compressed)
    engine.render.presence
  end

  ## ===== HOME PAGE =====

  def self.home_style
    style = Setting.get('home_css')
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
    engine = SassC::Engine.new(home_style, style: :compressed)
    engine.render.presence || '.home-page {}'
  end
end
