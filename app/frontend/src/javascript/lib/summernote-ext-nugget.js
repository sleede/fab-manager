// Inspired by: https://github.com/pHAlkaline/summernote-plugins/tree/master/plugins/nugget

(function (factory) {
  /* global define */
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['jquery'], factory);
  } else if (typeof module === 'object' && module.exports) {
    // Node/CommonJS
    module.exports = factory(require('jquery'));
  } else {
    // Browser globals
    factory(window.jQuery);
  }
}(function ($) {


  $.extend($.summernote.options, {
    nugget: {
      list: []
    }

  });
  $.extend(true, $.summernote, {
    // add localization texts
    lang: {
      'en-US': {
        nugget: {
          Nugget: 'Nugget',
          Insert_nugget: 'Insert Nugget'

        }
      },
      'en-GB': {
        nugget: {
          Nugget: 'Nugget',
          Insert_nugget: 'Insert Nugget'

        }
      },
      'pt-PT': {
        nugget: {
          Nugget: 'Pepita',
          Insert_nugget: 'Inserir pepita'

        }
      },
      'it-IT': {
        nugget: {
          Nugget: 'Pepite',
          Insert_nugget: 'Pepite Inserto'

        }
      }
    }
  });
  // Extends plugins for adding nuggets.
  //  - plugin is external module for customizing.
  $.extend($.summernote.plugins, {
    /**
     * @param {Object} context - context object has status of editor.
     */
    'nugget': function (context) {
      // ui has renders to build ui elements.
      //  - you can create a button with `ui.button`
      const ui = $.summernote.ui;
      const options = context.options.nugget;
      const context_options = context.options;
      const lang = context_options.langInfo;
      const defaultOptions = {
        label: lang.nugget.Nugget,
        tooltip: lang.nugget.Insert_nugget
      };

      // Assign default values if not supplied
      for (const propertyName in defaultOptions) {
        if (options.hasOwnProperty(propertyName) === false) {
          options[propertyName] = defaultOptions[propertyName];
        }
      }

      // add hello button
      context.memo('button.nugget', function () {
        // create button

        const button = ui.buttonGroup([
          ui.button({
            className: 'dropdown-toggle',
            contents: '<span class="nugget">' + options.label + ' </span><span class="note-icon-caret"></span>',
            tooltip: options.tooltip,
            data: {
              toggle: 'dropdown'
            }
          }),
          ui.dropdown({
            className: 'dropdown-nugget',
            contents: options.list.map((i) => {
              const li = document.createElement('li');
              const a = document.createElement('a');
              a.innerHTML = i.trim();
              a.setAttribute('href', '#');
              li.appendChild(a);
              return li.outerHTML;
            }),
            click: function (event) {
              event.preventDefault();

              const $button = $(event.target);
              const value = $button[0].outerHTML;
              const node = document.createElement('div');
              node.innerHTML = value.trim();
              context.invoke('editor.insertNode', node.firstChild);

            }
          })
        ]);

        // create jQuery object from button instance.
        return button.render();
      });
    }

  });

}));
