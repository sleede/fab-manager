# frozen_string_literal: true

# List of all allowed values for RAILS_LOCALE
I18n.config.available_locales += %i[de de-AT de-CH de-DE
                                    en en-AU en-CA en-GB en-IE en-IN en-NZ en-US en-ZA
                                    fr fr-CA fr-CH fr-CM fr-FR
                                    es es-419 es-AR es-CL es-CO es-CR es-DO es-EC es-ES es-MX es-PA es-PE es-US es-VE
                                    no
                                    pt pt-BR
                                    it it-CH
                                    zu]
# we allow the Zulu locale (zu) as it is used for In-Context translation
# @see https://support.crowdin.com/in-context-localization/

#
# /!\ ALL locales SHOULD be configured accordingly with the default_locale. /!\
#
I18n.config.default_locale = Rails.application.secrets.rails_locale.to_s.split('-')[0]
I18n.config.locale = Rails.application.secrets.rails_locale
