import React, { useCallback, useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import useOnclickOutside from 'react-cool-onclickoutside';
import { Editor } from '@tiptap/react';
import { TextAa, TextBolder, TextItalic, TextUnderline, LinkSimpleHorizontal, ListBullets, Quotes, Trash, CheckCircle } from 'phosphor-react';

interface MenuBarProps {
  paragraphTools?: boolean,
  editor?: Editor,
}

/**
 * This component is the menu bar for the WYSIWYG text editor
 */
export const MenuBar: React.FC<MenuBarProps> = ({ editor, paragraphTools }) => {
  const { t } = useTranslation('shared');

  const [linkMenu, setLinkMenu] = useState<boolean>(false);
  const resetUrl = { href: '', target: '_blank' };
  const [url, setUrl] = useState(resetUrl);
  const ref = useOnclickOutside(() => {
    setLinkMenu(false);
  });

  // Reset state values when the link menu is closed
  useEffect(() => {
    if (!linkMenu) {
      setUrl(resetUrl);
    }
  }, [linkMenu]);

  // Toggle link menu's visibility
  const toggleLinkMenu = () => {
    if (!linkMenu) {
      setLinkMenu(true);
      const previousUrl = {
        href: editor.getAttributes('link').href,
        target: editor.getAttributes('link').target || ''
      };
      // display selected text's attributes if it's a link
      if (previousUrl.href) {
        setUrl(previousUrl);
      }
    } else {
      setLinkMenu(false);
      setUrl(resetUrl);
    }
  };

  // Set link's target
  const toggleTarget = (evt) => {
    evt.target.checked
      ? setUrl({ href: url.href, target: '_blank' })
      : setUrl({ href: url.href, target: '' });
  };

  // Update url
  const handleChange = (evt) => {
    setUrl({ ...url, href: evt.target.value });
  };
  // Support keyboard "Enter" key event to validate
  const handleEnter = (evt) => {
    if (evt.keyCode === 13) {
      setLink();
    }
  };

  // Update the selected link
  const setLink = useCallback((closeLinkMenu?: boolean) => {
    if (url.href === '') {
      unsetLink();
      return;
    }
    editor.chain().focus().extendMarkRange('link').setLink({ href: url.href, target: url.target }).run();
    if (closeLinkMenu) {
      setLinkMenu(false);
    }
  }, [editor, url]);

  // Remove the link tag from the selected text
  const unsetLink = () => {
    editor.chain().focus().extendMarkRange('link').unsetLink().run();
    setLinkMenu(false);
  };

  if (!editor) {
    return null;
  }

  return (
    <>
      <div className='fab-textEditor-menu'>
        { paragraphTools &&
        (<>
          <button
            type='button'
            onClick={() => editor.chain().focus().toggleHeading({ level: 3 }).run()}
            className={editor.isActive('heading', { level: 3 }) ? 'is-active' : ''}
          >
            <TextAa size={24} />
          </button>
          <button
            type='button'
            onClick={() => editor.chain().focus().toggleBulletList().run()}
            className={editor.isActive('bulletList') ? 'is-active' : ''}
          >
            <ListBullets size={24} />
          </button>
          <button
            type='button'
            onClick={() => editor.chain().focus().toggleBlockquote().run()}
            className={editor.isActive('blockquote') ? 'is-active' : ''}
          >
            <Quotes size={24} />
          </button>
          <span className='divider'></span>
        </>)
        }
        <button
          type='button'
          onClick={() => editor.chain().focus().toggleBold().run()}
          className={editor.isActive('bold') ? 'is-active' : ''}
        >
          <TextBolder size={24} />
        </button>
        <button
          type='button'
          onClick={() => editor.chain().focus().toggleItalic().run()}
          className={editor.isActive('italic') ? 'is-active' : ''}
        >
          <TextItalic size={24} />
        </button>
        <button
          type='button'
          onClick={() => editor.chain().focus().toggleUnderline().run()}
          className={editor.isActive('underline') ? 'is-active' : ''}
        >
          <TextUnderline size={24} />
        </button>
        <button
          type='button'
          onClick={toggleLinkMenu}
          className={`ignore-onclickoutside ${editor.isActive('link') ? 'is-active' : ''}`}
        >
          <LinkSimpleHorizontal size={24} />
        </button>
      </div>
      <div ref={ref} className={`fab-textEditor-linkMenu ${linkMenu ? 'is-active' : ''}`}>
        <div className="url">
          <input value={url.href} onChange={handleChange} onKeyDown={handleEnter} type="text" placeholder={t('app.shared.text_editor.link_placeholder')} />
          <button type='button' onClick={unsetLink}>
            <Trash size={24} />
          </button>
        </div>
        <div>
          <label className='tab'>
            <p>{t('app.shared.text_editor.new_tab')}</p>
            <input type="checkbox" onChange={toggleTarget} checked={url.target === '_blank'} />
            <span className='switch'></span>
          </label>
          <button type='button' onClick={() => setLink(true)}>
            <CheckCircle size={24} />
          </button>
        </div>
      </div>
    </>
  );
};
