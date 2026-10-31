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
