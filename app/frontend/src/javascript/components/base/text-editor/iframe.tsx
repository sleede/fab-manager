import { Node } from '@tiptap/core';

export interface IframeOptions {
  allowFullscreen: boolean,
  HTMLAttributes: {
    [key: string]: string
  },
}

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    iframe: {
      /**
       * Add an iframe to embed a video
       */
      setIframe: (options: { src: string }) => ReturnType,
    }
  }
}

export default Node.create<IframeOptions>({
  name: 'iframe',

  group: 'block',

  atom: true,

  addOptions () {
    return {
      allowFullscreen: true,
      HTMLAttributes: {
        class: 'fab-textEditor-video'
      }
    };
  },

  addAttributes () {
    return {
      src: {
        default: null
      },
      frameborder: {
        default: 0
      },
      allowfullscreen: {
        default: this.options.allowFullscreen,
        parseHTML: () => this.options.allowFullscreen
      }
    };
  },

  parseHTML () {
    return [{
      tag: 'iframe'
    }];
  },

  renderHTML ({ HTMLAttributes }) {
    return ['div', this.options.HTMLAttributes, ['iframe', HTMLAttributes]];
  },

  addCommands () {
    return {
      setIframe: (options: { src: string }) => ({ tr, dispatch }) => {
        const { selection } = tr;
        const node = this.type.create(options);

        if (dispatch) {
          tr.replaceRangeWith(selection.from, selection.to, node);
        }

        return true;
      }
    };
  }
});
