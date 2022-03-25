import React, { useCallback, useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import useOnclickOutside from 'react-cool-onclickoutside';
import { Editor } from '@tiptap/react';
import { TextAa, TextBolder, TextItalic, TextUnderline, LinkSimpleHorizontal, ListBullets, Quotes, Trash, CheckCircle, VideoCamera } from 'phosphor-react';

interface MenuBarProps {
  paragraphTools?: boolean,
  video?: boolean,
  editor?: Editor,
}

/**
 * This component is the menu bar for the WYSIWYG text editor
 */
export const MenuBar: React.FC<MenuBarProps> = ({ editor, paragraphTools, video }) => {
  const { t } = useTranslation('shared');

  const [submenu, setSubmenu] = useState('');
  const resetUrl = { href: '', target: '_blank' };
  const [url, setUrl] = useState(resetUrl);
  const [videoProvider, setVideoProvider] = useState('youtube');
  const [videoId, setVideoId] = useState('');

  // Reset state values when the submenu is closed
  useEffect(() => {
    if (!submenu) {
      setUrl(resetUrl);
      setVideoProvider('youtube');
    }
  }, [submenu]);

  // Close the submenu frame on click outside
  const ref = useOnclickOutside(() => {
    setSubmenu('');
  });

  // Toggle link menu's visibility
  const toggleLinkMenu = () => {
    if (submenu !== 'link') {
      setSubmenu('link');
      const previousUrl = {
        href: editor.getAttributes('link').href,
        target: editor.getAttributes('link').target || ''
      };
      // display selected text's attributes if it's a link
      if (previousUrl.href) {
        setUrl(previousUrl);
      }
    } else {
      setSubmenu('');
    }
  };

  // Set link's target
  const toggleTarget = (evt) => {
    evt.target.checked
      ? setUrl({ href: url.href, target: '_blank' })
      : setUrl({ href: url.href, target: '' });
  };

  // Update url
  const linkUrlChange = (evt) => {
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
      setSubmenu('');
    }
  }, [editor, url]);

  // Remove the link tag from the selected text
  const unsetLink = () => {
    editor.chain().focus().extendMarkRange('link').unsetLink().run();
    setSubmenu('');
  };

  // Toggle video menu's visibility
  const toggleVideoMenu = () => {
    if (submenu !== 'video') {
      setSubmenu('video');
    } else {
      setSubmenu('');
    }
  };

  // Store selected video provider in state
  const handleSelect = (evt) => {
    setVideoProvider(evt.target.value);
  };
  // Store video id in state
  const VideoUrlChange = (evt) => {
    const id = evt.target.value.match(/([^/]+$)/g);
    setVideoId(id);
  };
  // Insert iframe containing the video player
  const addIframe = () => {
    let videoUrl = '';
    switch (videoProvider) {
      case 'youtube':
        videoUrl = `https://www.youtube.com/embed/${videoId}`;
        break;
      case 'vimeo':
        videoUrl = `https://player.vimeo.com/video/${videoId}`;
        break;
      case 'dailymotion':
        videoUrl = `https://www.dailymotion.com/embed/video/${videoId}`;
        break;
      default:
        break;
    }
    editor.chain().focus().setIframe({ src: videoUrl }).run();
    setSubmenu('');
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
        { video &&
        (<>
          <button
            type='button'
            onClick={toggleVideoMenu}
          >
            <VideoCamera size={24} />
          </button>
        </>)
        }
      </div>
      <div ref={ref} className={`fab-textEditor-subMenu ${submenu ? 'is-active' : ''}`}>
        { submenu === 'link' &&
          (<>
            <div>
              <input value={url.href} onChange={linkUrlChange} onKeyDown={handleEnter} type="text" placeholder={t('app.shared.text_editor.link_placeholder')} />
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
          </>)
        }
        { submenu === 'video' &&
          (<>
            <select name="provider" onChange={handleSelect}>
              <option value="youtube">YouTube</option>
              <option value="vimeo">Vimeo</option>
              <option value="dailymotion">Dailymotion</option>
            </select>
            <div>
              <input type="text" onChange={VideoUrlChange} placeholder={t('app.shared.text_editor.link_placeholder')} />
              <button type='button' onClick={() => addIframe()}>
                <CheckCircle size={24} />
              </button>
            </div>
          </>)
        }
      </div>
    </>
  );
};
