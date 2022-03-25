import React from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { IApplication } from '../../../models/application';
import { Loader } from '../loader';
import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import Placeholder from '@tiptap/extension-placeholder';
import CharacterCount from '@tiptap/extension-character-count';
import Underline from '@tiptap/extension-underline';
import Link from '@tiptap/extension-link';
import Iframe from './iframe';
import { MenuBar } from './menu-bar';
import { WarningOctagon } from 'phosphor-react';

declare const Application: IApplication;

interface FabTextEditorProps {
  label?: string,
  paragraphTools?: boolean,
  content?: string,
  limit?: number,
  video?: boolean,
  onChange?: (content: string) => void,
  placeholder?: string,
  error?: string
}

/**
 * This component is a WYSIWYG text editor
 */
export const FabTextEditor: React.FC<FabTextEditorProps> = ({ label, paragraphTools, content, limit = 400, video, onChange, placeholder, error }) => {
  const { t } = useTranslation('shared');
  const placeholderText = placeholder || t('app.shared.text_editor.placeholder');
  // TODO: Add ctrl+click on link to visit

  // Setup the editor
  // Extensions add functionalities to the editor (Bold, Italic…)
  // Events fire action (onUpdate -> get the content as HTML)
  const editor = useEditor({
    extensions: [
      StarterKit.configure({
        heading: {
          levels: [3]
        }
      }),
      Underline,
      Link.configure({
        openOnClick: false
      }),
      Placeholder.configure({
        placeholder: placeholderText
      }),
      CharacterCount.configure({
        limit
      }),
      Iframe
    ],
    content,
    onUpdate: ({ editor }) => {
      onChange(editor.getHTML());
    }
  });

  const focusEditor = () => {
    editor.commands.focus('start');
  };

  return (
    <>
      {label && <label onClick={focusEditor} className="fab-textEditor-label">{label}</label>}
      <div className="fab-textEditor">
        <MenuBar editor={editor} paragraphTools={paragraphTools} video={video} />
        <EditorContent editor={editor} />
        <div className="fab-textEditor-character-count">
          {editor?.storage.characterCount.characters()} / {limit}
        </div>
        {error &&
          <div className="fab-textEditor-error">
            <WarningOctagon size={24} />
            <p className="">{error}</p>
          </div>
        }
      </div>
    </>
  );
};

const FabTextEditorWrapper: React.FC<FabTextEditorProps> = ({ label, paragraphTools, content, limit, video, placeholder, error }) => {
  return (
    <Loader>
      <FabTextEditor label={label} paragraphTools={paragraphTools} content={content} limit={limit} video={video} placeholder={placeholder} error={error} />
    </Loader>
  );
};

Application.Components.component('fabTextEditor', react2angular(FabTextEditorWrapper, ['label', 'paragraphTools', 'content', 'limit', 'video', 'placeholder', 'error']));
