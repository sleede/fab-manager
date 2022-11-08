import React, { useCallback, useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import useOnclickOutside from 'react-cool-onclickoutside';
import { Editor } from '@tiptap/react';
import { TextAa, TextBolder, TextItalic, TextUnderline, LinkSimpleHorizontal, ListBullets, Quotes, Trash, CheckCircle, VideoCamera, Image } from 'phosphor-react';

interface MenuBarProps {
  editor?: Editor,
  heading?: boolean,
  bulletList?: boolean,
  blockquote?: boolean,
  link?: boolean,
  video?: boolean,
  image?: boolean,
  disabled?: boolean,
}

/**
 * This component is the menu bar for the WYSIWYG text editor
 */
export const MenuBar: React.FC<MenuBarProps> = ({ editor, heading, bulletList, blockquote, link, video, image, disabled = false }) => {
  const { t } = useTranslation('shared');

  const [submenu, setSubmenu] = useState('');
  const resetUrl = { href: '', target: '_blank' };
  const [url, setUrl] = useState(resetUrl);
  const [videoProvider, setVideoProvider] = useState('youtube');
  const [videoId, setVideoId] = useState('');
  const [imageUrl, setImageUrl] = useState('');

  // Reset state values when the submenu is closed
  useEffect(() => {
    if (!submenu) {
      setUrl(resetUrl);
      setVideoProvider('youtube');
      setImageUrl('');
    }
  }, [submenu]);

  // Close the submenu frame on click outside
  const ref = useOnclickOutside(() => {
    setSubmenu('');
  });

  // Toggle submenu's visibility
  const toggleSubmenu = (type) => {
    if (submenu !== type) {
      setSubmenu(type);
      if (type === 'link') {
        if (editor.view.state.selection.from === editor.view.state.selection.to) {
          setSubmenu('');
          return;
        }
        const previousUrl = {
          href: editor.getAttributes('link').href,
          target: editor.getAttributes('link').target || ''
        };
        // display selected text's attributes if it's a link
        if (previousUrl.href) {
          setUrl(previousUrl);
        }
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
      setLink(true);
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

  // Store selected video provider in state
  const handleSelect = (evt) => {
    setVideoProvider(evt.target.value);
  };
  // Store video id in state
  const videoUrlChange = (evt) => {
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

  // Store image url in state
  const imageUrlChange = (evt) => {
    setImageUrl(evt.target.value);
  };
  // Insert image
  const addImage = () => {
    if (imageUrl) {
      editor.chain().focus().setImage({ src: imageUrl }).run();
      setSubmenu('');
    }
  };

  if (!editor) {
    return null;
  }

  return (
    <>
      <div className={`fab-text-editor-menu ${disabled ? 'fab-text-editor-menu--disabled' : ''}`}>
        {heading &&
          <button
            type='button'
            onClick={() => editor.chain().focus().toggleHeading({ level: 3 }).run()}
            disabled={disabled}
            className={editor.isActive('heading', { level: 3 }) ? 'is-active' : ''}
          >
            <TextAa size={24} />
          </button>
        }
        {bulletList &&
          <button
            type='button'
            onClick={() => editor.chain().focus().toggleBulletList().run()}
            disabled={disabled}
            className={editor.isActive('bulletList') ? 'is-active' : ''}
          >
            <ListBullets size={24} />
          </button>
        }
        {blockquote &&
          <button
            type='button'
            onClick={() => editor.chain().focus().toggleBlockquote().run()}
            disabled={disabled}
            className={editor.isActive('blockquote') ? 'is-active' : ''}
          >
            <Quotes size={24} />
          </button>
        }
        { (heading || bulletList || blockquote) && <span className='menu-divider'></span> }
        <button
          type='button'
          onClick={() => editor.chain().focus().toggleBold().run()}
          disabled={disabled}
          className={editor.isActive('bold') ? 'is-active' : ''}
        >
          <TextBolder size={24} />
        </button>
        <button
          type='button'
          onClick={() => editor.chain().focus().toggleItalic().run()}
          disabled={disabled}
          className={editor.isActive('italic') ? 'is-active' : ''}
        >
          <TextItalic size={24} />
        </button>
        <button
          type='button'
          onClick={() => editor.chain().focus().toggleUnderline().run()}
          disabled={disabled}
          className={editor.isActive('underline') ? 'is-active' : ''}
        >
          <TextUnderline size={24} />
        </button>
        {link &&
          <button
            type='button'
            onClick={() => toggleSubmenu('link')}
            disabled={disabled}
            className={`ignore-onclickoutside ${editor.isActive('link') ? 'is-active' : ''}`}
          >
            <LinkSimpleHorizontal size={24} />
          </button>
        }
        { (video || image) && <span className='menu-divider'></span> }
        { video &&
        (<>
          <button
            type='button'
            disabled={disabled}
            onClick={() => toggleSubmenu('video')}
          >
            <VideoCamera size={24} />
          </button>
        </>)
        }
        { image &&
        (<>
          <button
            type='button'
            disabled={disabled}
            onClick={() => toggleSubmenu('image')}
          >
            <Image size={24} />
          </button>
        </>)
        }
      </div>

      <div ref={ref} className={`fab-text-editor-subMenu ${submenu ? 'is-active' : ''}`}>
        { submenu === 'link' &&
          (<>
            <h6>{t('app.shared.text_editor.menu_bar.add_link')}</h6>
            <div>
              <input value={url.href} onChange={linkUrlChange} onKeyDown={handleEnter} type="text" placeholder={t('app.shared.text_editor.menu_bar.link_placeholder')} />
              <button type='button' onClick={unsetLink}>
                <Trash size={24} />
              </button>
            </div>
            <div>
              <label className='tab'>
                <p>{t('app.shared.text_editor.menu_bar.new_tab')}</p>
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
            <h6>{t('app.shared.text_editor.menu_bar.add_video')}</h6>
            <select name="provider" onChange={handleSelect}>
              <option value="youtube">YouTube</option>
              <option value="vimeo">Vimeo</option>
              <option value="dailymotion">Dailymotion</option>
            </select>
            <div>
              <input type="text" onChange={videoUrlChange} placeholder={t('app.shared.text_editor.menu_bar.url_placeholder')} />
              <button type='button' onClick={() => addIframe()}>
                <CheckCircle size={24} />
              </button>
            </div>
          </>)
        }
        { submenu === 'image' &&
          (<>
            <h6>{t('app.shared.text_editor.menu_bar.add_image')}</h6>
            <div>
              <input type="text" onChange={imageUrlChange} placeholder={t('app.shared.text_editor.menu_bar.url_placeholder')} />
              <button type='button' onClick={() => addImage()}>
                <CheckCircle size={24} />
              </button>
            </div>
          </>)
        }
      </div>
    </>
  );
};
