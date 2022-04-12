# components

This directory is holding the components built with [React](https://reactjs.org/).

During the migration phase, these components may be included in [the legacy angularJS app](../../templates) using [react2angular](https://github.com/coatue-oss/react2angular).

These components must be written using the following conventions:
- The component name must be in CamelCase.
- The component must be exported as a named export (no `export default`).
- A component `FooBar` must have a `className="foo-bar"` attribute on its top-level element.
- The stylesheet associated with the component must be located in `app/frontend/src/stylesheets/modules/same-directory-structure/foo-bar.scss`.
- All methods in the component must be commented with a comment block.
- Other constants and variables must be commented with an inline block.
- Depending on if we want to use the `<Suspense>` wrapper or not, we can export the component directly or wrap it in a `<Loader>` wrapper.
- When a component is used in angularJS, the wrapper is required. The component must be named like `const Foo` (no export if not used in React) and must have a `const FooWrapper` at the end of its file, which wraps the component in a `<Loader>`.
- Translations must be grouped per component. For example, the `FooBar` component must have its translations in the  `config/locales/app.$SCOPE.en.yml` file, under the `foo_bar` key.

