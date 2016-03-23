require 'mail'
# This is trying to workaround an issue in `mail` gem
# Issue: https://github.com/mikel/mail/issues/912
#
# Since with current version (2.6.3) it is using `autoload`
# And as mentioned by a comment in the issue above
# It might not be thread-safe and
# might have problem in threaded environment like Sidekiq workers
#
# So we try to require the file manually here to avoid
# "uninitialized constant" error
#
# This is merely a workaround since
# it should fixed by not using the `autoload`
require 'mail/parsers/content_type_parser'