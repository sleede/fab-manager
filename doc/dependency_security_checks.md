# Dependency security regression checks

Run these checks with the repository Ruby/Bundler versions on Linux, using disposable
PostgreSQL/Redis/Elasticsearch services and synthetic fixtures. See `scripts/tests.sh`
and the development guide for the standard test entry point. Test databases must be
separate from shared development and production databases.

## Uploads and URLs (R3)

`bash scripts/tests.sh test/lib/upload_dependency_test.rb test/integration/supporting_document_files_authorization_test.rb test/integration/projects_test.rb --seed 12345`

Checks exercise real CarrierWave uploaders, ImageMagick variants, content and extension
validation, configured model size limits, CAD configuration, removal, private destination
rejection, and Addressable normalization/template round trips. Image processing remains
on the compatible 1.13 family. Temporary upload roots keep test files outside user storage.

## Tokens and passwords (R4)

`bash scripts/tests.sh test/lib/authentication_dependency_test.rb test/integration/rack_compatibility_test.rb test/models/user_test.rb --seed 12345`

JWT tests use real signatures and explicit algorithms/claims, including nil/empty key
rejection. A simulated OAuth2 exchange exercises the installed parent API. Devise reads
a synthetic hash produced by the previous bcrypt and verifies newly generated passwords.
The existing Rack checks retain CSRF validation during login/logout. JWT 3 is outside
the OAuth2 parent's supported range. The bcrypt Java/JRuby advisory does not apply to MRI.
