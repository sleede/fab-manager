/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
describe("Bootstrap Switch", function() {

  beforeEach(function() {
    $.support.transition = false;
    return $.fx.off = true;
  });

  afterEach(() => $(`.${$.fn.bootstrapSwitch.defaults.baseClass}`).bootstrapSwitch("destroy"));

  const createElement = () =>
    $("<input>", {
      type: "checkbox",
      class: "switch"
    }
    ).appendTo("body")
  ;

  const getOptions = $element => $element.data("bootstrap-switch").options;

  it("should set the default options as element options, except state", function() {
    const $switch = createElement().prop("checked", true).bootstrapSwitch();
    return expect(getOptions($switch)).toEqual($.fn.bootstrapSwitch.defaults);
  });

  return it("should override default options with initialization ones", function() {
    const $switch = createElement().prop("checked", false).bootstrapSwitch();
    const $switch2 = createElement().bootstrapSwitch({state: false});
    expect(getOptions($switch).state).toBe(false);
    return expect(getOptions($switch2).state).toBe(false);
  });
});
