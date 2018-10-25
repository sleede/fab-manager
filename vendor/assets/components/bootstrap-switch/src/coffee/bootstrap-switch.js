/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
(function($, window) {
  "use strict";

  class BootstrapSwitch {
    static initClass() {
  
      this.prototype._constructor = BootstrapSwitch;
    }
    constructor(element, options) {
      if (options == null) { options = {}; }
      this.$element = $(element);
      this.options = $.extend({}, $.fn.bootstrapSwitch.defaults, {
        state: this.$element.is(":checked"),
        size: this.$element.data("size"),
        animate: this.$element.data("animate"),
        disabled: this.$element.is(":disabled"),
        readonly: this.$element.is("[readonly]"),
        indeterminate: this.$element.data("indeterminate"),
        inverse: this.$element.data("inverse"),
        radioAllOff: this.$element.data("radio-all-off"),
        onColor: this.$element.data("on-color"),
        offColor: this.$element.data("off-color"),
        onText: this.$element.data("on-text"),
        offText: this.$element.data("off-text"),
        labelText: this.$element.data("label-text"),
        handleWidth: this.$element.data("handle-width"),
        labelWidth: this.$element.data("label-width"),
        baseClass: this.$element.data("base-class"),
        wrapperClass: this.$element.data("wrapper-class")
      }
      , options);
      this.$wrapper = $("<div>", {
        class: (() => {
          const classes = [`${this.options.baseClass}`].concat(this._getClasses(this.options.wrapperClass));

          classes.push(this.options.state ? `${this.options.baseClass}-on` : `${this.options.baseClass}-off`);
          if (this.options.size != null) { classes.push(`${this.options.baseClass}-${this.options.size}`); }
          if (this.options.disabled) { classes.push(`${this.options.baseClass}-disabled`); }
          if (this.options.readonly) { classes.push(`${this.options.baseClass}-readonly`); }
          if (this.options.indeterminate) { classes.push(`${this.options.baseClass}-indeterminate`); }
          if (this.options.inverse) { classes.push(`${this.options.baseClass}-inverse`); }
          if (this.$element.attr("id")) { classes.push(`${this.options.baseClass}-id-${this.$element.attr("id")}`); }
          return classes.join(" ");
        })()
      }
      );
      this.$container = $("<div>",
        {class: `${this.options.baseClass}-container`});
      this.$on = $("<span>", {
        html: this.options.onText,
        class: `${this.options.baseClass}-handle-on ${this.options.baseClass}-${this.options.onColor}`
      }
      );
      this.$off = $("<span>", {
        html: this.options.offText,
        class: `${this.options.baseClass}-handle-off ${this.options.baseClass}-${this.options.offColor}`
      }
      );
      this.$label = $("<span>", {
        html: this.options.labelText,
        class: `${this.options.baseClass}-label`
      }
      );

      // set up events
      this.$element.on("init.bootstrapSwitch", function() { return this.options.onInit.apply(element, arguments); }.bind(this));
      this.$element.on("switchChange.bootstrapSwitch", function() { return this.options.onSwitchChange.apply(element, arguments); }.bind(this));

      // reassign elements after dom modification
      this.$container = this.$element.wrap(this.$container).parent();
      this.$wrapper = this.$container.wrap(this.$wrapper).parent();

      // insert handles and label and trigger event
      this.$element
      .before(this.options.inverse ? this.$off : this.$on)
      .before(this.$label)
      .before(this.options.inverse ? this.$on : this.$off);

      // indeterminate state
      if (this.options.indeterminate) { this.$element.prop("indeterminate", true); }

      // normalize handles width and set container position
      this._init();

      // initialise handlers
      this._elementHandlers();
      this._handleHandlers();
      this._labelHandlers();
      this._formHandler();
      this._externalLabelHandler();

      this.$element.trigger("init.bootstrapSwitch");
    }

    state(value, skip) {
      if (typeof value === "undefined") { return this.options.state; }
      if (this.options.disabled || this.options.readonly) { return this.$element; }
      if (this.options.state && !this.options.radioAllOff && this.$element.is(":radio")) { return this.$element; }

      // remove indeterminate
      if (this.options.indeterminate) { this.indeterminate(false); }
      value = !!value;

      this.$element.prop("checked", value).trigger("change.bootstrapSwitch", skip);
      return this.$element;
    }

    toggleState(skip) {
      if (this.options.disabled || this.options.readonly) { return this.$element; }

      if (this.options.indeterminate) {
        this.indeterminate(false);
        return this.state(true);
      } else {
        return this.$element.prop("checked", !this.options.state).trigger("change.bootstrapSwitch", skip);
      }
    }

    size(value) {
      if (typeof value === "undefined") { return this.options.size; }

      if (this.options.size != null) { this.$wrapper.removeClass(`${this.options.baseClass}-${this.options.size}`); }
      if (value) { this.$wrapper.addClass(`${this.options.baseClass}-${value}`); }
      this._width();
      this._containerPosition();
      this.options.size = value;
      return this.$element;
    }

    animate(value) {
      if (typeof value === "undefined") { return this.options.animate; }

      value = !!value;
      if (value === this.options.animate) { return this.$element; }

      return this.toggleAnimate();
    }

    toggleAnimate() {
      this.options.animate = !this.options.animate;

      this.$wrapper.toggleClass(`${this.options.baseClass}-animate`);
      return this.$element;
    }

    disabled(value) {
      if (typeof value === "undefined") { return this.options.disabled; }

      value = !!value;
      if (value === this.options.disabled) { return this.$element; }

      return this.toggleDisabled();
    }

    toggleDisabled() {
      this.options.disabled = !this.options.disabled;

      this.$element.prop("disabled", this.options.disabled);
      this.$wrapper.toggleClass(`${this.options.baseClass}-disabled`);
      return this.$element;
    }

    readonly(value) {
      if (typeof value === "undefined") { return this.options.readonly; }

      value = !!value;
      if (value === this.options.readonly) { return this.$element; }

      return this.toggleReadonly();
    }

    toggleReadonly() {
      this.options.readonly = !this.options.readonly;

      this.$element.prop("readonly", this.options.readonly);
      this.$wrapper.toggleClass(`${this.options.baseClass}-readonly`);
      return this.$element;
    }

    indeterminate(value) {
      if (typeof value === "undefined") { return this.options.indeterminate; }

      value = !!value;
      if (value === this.options.indeterminate) { return this.$element; }

      return this.toggleIndeterminate();
    }

    toggleIndeterminate() {
      this.options.indeterminate = !this.options.indeterminate;

      this.$element.prop("indeterminate", this.options.indeterminate);
      this.$wrapper.toggleClass(`${this.options.baseClass}-indeterminate`);
      this._containerPosition();
      return this.$element;
    }

    inverse(value) {
      if (typeof value === "undefined") { return this.options.inverse; }

      value = !!value;
      if (value === this.options.inverse) { return this.$element; }

      return this.toggleInverse();
    }

    toggleInverse() {
      this.$wrapper.toggleClass(`${this.options.baseClass}-inverse`);
      const $on = this.$on.clone(true);
      const $off = this.$off.clone(true);
      this.$on.replaceWith($off);
      this.$off.replaceWith($on);
      this.$on = $off;
      this.$off = $on;
      this.options.inverse = !this.options.inverse;
      return this.$element;
    }

    onColor(value) {
      const color = this.options.onColor;

      if (typeof value === "undefined") { return color; }

      if (color != null) { this.$on.removeClass(`${this.options.baseClass}-${color}`); }
      this.$on.addClass(`${this.options.baseClass}-${value}`);
      this.options.onColor = value;
      return this.$element;
    }

    offColor(value) {
      const color = this.options.offColor;

      if (typeof value === "undefined") { return color; }

      if (color != null) { this.$off.removeClass(`${this.options.baseClass}-${color}`); }
      this.$off.addClass(`${this.options.baseClass}-${value}`);
      this.options.offColor = value;
      return this.$element;
    }

    onText(value) {
      if (typeof value === "undefined") { return this.options.onText; }

      this.$on.html(value);
      this._width();
      this._containerPosition();
      this.options.onText = value;
      return this.$element;
    }

    offText(value) {
      if (typeof value === "undefined") { return this.options.offText; }

      this.$off.html(value);
      this._width();
      this._containerPosition();
      this.options.offText = value;
      return this.$element;
    }

    labelText(value) {
      if (typeof value === "undefined") { return this.options.labelText; }

      this.$label.html(value);
      this._width();
      this.options.labelText = value;
      return this.$element;
    }

    handleWidth(value) {
      if (typeof value === "undefined") { return this.options.handleWidth; }

      this.options.handleWidth = value;
      this._width();
      this._containerPosition();
      return this.$element;
    }

    labelWidth(value) {
      if (typeof value === "undefined") { return this.options.labelWidth; }

      this.options.labelWidth = value;
      this._width();
      this._containerPosition();
      return this.$element;
    }

    baseClass(value) {
      return this.options.baseClass;
    }

    wrapperClass(value) {
      if (typeof value === "undefined") { return this.options.wrapperClass; }

      if (!value) { value = $.fn.bootstrapSwitch.defaults.wrapperClass; }

      this.$wrapper.removeClass(this._getClasses(this.options.wrapperClass).join(" "));
      this.$wrapper.addClass(this._getClasses(value).join(" "));
      this.options.wrapperClass = value;
      return this.$element;
    }

    radioAllOff(value) {
      if (typeof value === "undefined") { return this.options.radioAllOff; }

      value = !!value;
      if (value === this.options.radioAllOff) { return this.$element; }

      this.options.radioAllOff = value;
      return this.$element;
    }

    onInit(value) {
      if (typeof value === "undefined") { return this.options.onInit; }

      if (!value) { value = $.fn.bootstrapSwitch.defaults.onInit; }

      this.options.onInit = value;
      return this.$element;
    }

    onSwitchChange(value) {
      if (typeof value === "undefined") { return this.options.onSwitchChange; }

      if (!value) { value = $.fn.bootstrapSwitch.defaults.onSwitchChange; }

      this.options.onSwitchChange = value;
      return this.$element;
    }

    destroy() {
      const $form = this.$element.closest("form");

      if ($form.length) { $form.off("reset.bootstrapSwitch").removeData("bootstrap-switch"); }
      this.$container.children().not(this.$element).remove();
      this.$element.unwrap().unwrap().off(".bootstrapSwitch").removeData("bootstrap-switch");
      return this.$element;
    }

    _width() {
      const $handles = this.$on.add(this.$off);

      // remove width from inline style
      $handles.add(this.$label).css("width", "");

      // save handleWidth for further label width calculation check
      const handleWidth = this.options.handleWidth === "auto"
      ? Math.max(this.$on.width(), this.$off.width())
      : this.options.handleWidth;

      // set handles width
      $handles.width(handleWidth);

      // set label width
      this.$label.width((index, width) => {
        if (this.options.labelWidth !== "auto") { return this.options.labelWidth; }

        if (width < handleWidth) { return handleWidth; } else { return width; }
      });

      // get handle and label widths
      this._handleWidth = this.$on.outerWidth();
      this._labelWidth = this.$label.outerWidth();

      // set container and wrapper widths
      this.$container.width((this._handleWidth * 2) + this._labelWidth);
      return this.$wrapper.width(this._handleWidth + this._labelWidth);
    }

    _containerPosition(state, callback) {
      if (state == null) { ({ state } = this.options); }
      this.$container
      .css("margin-left", () => {
        const values = [0, `-${this._handleWidth}px`];

        if (this.options.indeterminate) { return `-${this._handleWidth / 2}px`; }

        if (state) {
          if (this.options.inverse) { return values[1]; } else { return values[0]; }
        } else {
          if (this.options.inverse) { return values[0]; } else { return values[1]; }
        }
    });

      if (!callback) { return; }

      return setTimeout(() => callback()
      , 50);
    }

    _init() {
      let initInterval;
      const init = () => {
        this._width();
        return this._containerPosition(null, () => {
          if (this.options.animate) { return this.$wrapper.addClass(`${this.options.baseClass}-animate`); }
        });
      };

      if (this.$wrapper.is(":visible")) { return init(); }

      return initInterval = window.setInterval(() => {
        if (this.$wrapper.is(":visible")) {
          init();
          return window.clearInterval(initInterval);
        }
      }
      , 50);
    }

    _elementHandlers() {
      return this.$element.on({
        "change.bootstrapSwitch": (e, skip) => {
          e.preventDefault();
          e.stopImmediatePropagation();

          const state = this.$element.is(":checked");

          this._containerPosition(state);
          if (state === this.options.state) { return; }

          this.options.state = state;
          this.$wrapper.toggleClass(`${this.options.baseClass}-off`).toggleClass(`${this.options.baseClass}-on`);

          if (!skip) {
            if (this.$element.is(":radio")) {
              $(`[name='${this.$element.attr('name')}']`)
              .not(this.$element)
              .prop("checked", false)
              .trigger("change.bootstrapSwitch", true);
            }

            return this.$element.trigger("switchChange.bootstrapSwitch", [state]);
          }
        },

        "focus.bootstrapSwitch": e => {
          e.preventDefault();
          return this.$wrapper.addClass(`${this.options.baseClass}-focused`);
        },

        "blur.bootstrapSwitch": e => {
          e.preventDefault();
          return this.$wrapper.removeClass(`${this.options.baseClass}-focused`);
        },

        "keydown.bootstrapSwitch": e => {
          if (!e.which || this.options.disabled || this.options.readonly) { return; }

          switch (e.which) {
            case 37:
              e.preventDefault();
              e.stopImmediatePropagation();

              return this.state(false);
            case 39:
              e.preventDefault();
              e.stopImmediatePropagation();

              return this.state(true);
          }
        }
      });
    }

    _handleHandlers() {
      this.$on.on("click.bootstrapSwitch", event => {
        event.preventDefault();
        event.stopPropagation();

        this.state(false);
        return this.$element.trigger("focus.bootstrapSwitch");
      });

      return this.$off.on("click.bootstrapSwitch", event => {
        event.preventDefault();
        event.stopPropagation();

        this.state(true);
        return this.$element.trigger("focus.bootstrapSwitch");
      });
    }

    _labelHandlers() {
      return this.$label.on({
        "mousedown.bootstrapSwitch touchstart.bootstrapSwitch": e => {
          if (this._dragStart || this.options.disabled || this.options.readonly) { return; }

          e.preventDefault();
          e.stopPropagation();

          this._dragStart = (e.pageX || e.originalEvent.touches[0].pageX) - parseInt(this.$container.css("margin-left"), 10);
          if (this.options.animate) { this.$wrapper.removeClass(`${this.options.baseClass}-animate`); }
          return this.$element.trigger("focus.bootstrapSwitch");
        },

        "mousemove.bootstrapSwitch touchmove.bootstrapSwitch": e => {
          if (this._dragStart == null) { return; }

          e.preventDefault();

          const difference = (e.pageX || e.originalEvent.touches[0].pageX) - this._dragStart;
          if ((difference < -this._handleWidth) || (difference > 0)) { return; }

          this._dragEnd = difference;
          return this.$container.css("margin-left", `${this._dragEnd}px`);
        },

        "mouseup.bootstrapSwitch touchend.bootstrapSwitch": e => {
          let state;
          if (!this._dragStart) { return; }

          e.preventDefault();

          if (this.options.animate) { this.$wrapper.addClass(`${this.options.baseClass}-animate`); }
          if (this._dragEnd) {
            state = this._dragEnd > -(this._handleWidth / 2);

            this._dragEnd = false;
            this.state(this.options.inverse ? !state : state);
          } else {
            this.state(!this.options.state);
          }

          return this._dragStart = false;
        },

        "mouseleave.bootstrapSwitch": e => {
          return this.$label.trigger("mouseup.bootstrapSwitch");
        }
      });
    }

    _externalLabelHandler() {
      const $externalLabel = this.$element.closest("label");

      return $externalLabel.on("click", event => {
        event.preventDefault();
        event.stopImmediatePropagation();

        // reimplement toggle state on external label only if it is not the target
        if (event.target === $externalLabel[0]) { return this.toggleState(); }
    });
    }

    _formHandler() {
      const $form = this.$element.closest("form");

      if ($form.data("bootstrap-switch")) { return; }

      return $form
      .on("reset.bootstrapSwitch", () =>
        window.setTimeout(() =>
          $form
          .find("input")
          .filter( function() { return $(this).data("bootstrap-switch"); })
          .each(function() { return $(this).bootstrapSwitch("state", this.checked); })
        
        , 1)
    ).data("bootstrap-switch", true);
    }

    _getClasses(classes) {
      if (!$.isArray(classes)) { return [`${this.options.baseClass}-${classes}`]; }

      const cls = [];
      for (let c of Array.from(classes)) {
        cls.push(`${this.options.baseClass}-${c}`);
      }
      return cls;
    }
  }
  BootstrapSwitch.initClass();

  $.fn.bootstrapSwitch = function(option, ...args) {
    let ret = this;
    this.each(function() {
      const $this = $(this);
      let data = $this.data("bootstrap-switch");

      if (!data) { $this.data("bootstrap-switch", (data = new BootstrapSwitch(this, option))); }
      if (typeof option === "string") { return ret = data[option].apply(data, args); }
    });
    return ret;
  };

  $.fn.bootstrapSwitch.Constructor = BootstrapSwitch;
  return $.fn.bootstrapSwitch.defaults = {
    state: true,
    size: null,
    animate: true,
    disabled: false,
    readonly: false,
    indeterminate: false,
    inverse: false,
    radioAllOff: false,
    onColor: "primary",
    offColor: "default",
    onText: "ON",
    offText: "OFF",
    labelText: "&nbsp;",
    handleWidth: "auto",
    labelWidth: "auto",
    baseClass: "bootstrap-switch",
    wrapperClass: "wrapper",
    onInit() {},
    onSwitchChange() {}
  };
})(window.jQuery, window);
