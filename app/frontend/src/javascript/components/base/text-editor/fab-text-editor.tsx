import React, { forwardRef, RefObject, useEffect, useImperativeHandle, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { useEditor, EditorContent, Editor } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import Placeholder from '@tiptap/extension-placeholder';
import CharacterCount from '@tiptap/extension-character-count';
import Underline from '@tiptap/extension-underline';
import Link from '@tiptap/extension-link';
import Iframe from './iframe';
import Image from '@tiptap/extension-image';
import { MenuBar } from './menu-bar';
import { WarningOctagon } from 'phosphor-react';

interface FabTextEditorProps {
  heading?: boolean,
  bulletList?: boolean,
  blockquote?: boolean,
  link?: boolean,
  video?: boolean,
  image?: boolean,
  content?: string,
  limit?: number,
  onChange?: (content: string) => void,
  placeholder?: string,
  error?: string,
  disabled?: boolean
}

export interface FabTextEditorRef {
  focus: () => void
}

/**
 * This component is a WYSIWYG text editor
 */
export const FabTextEditor: React.ForwardRefRenderFunction<FabTextEditorRef, FabTextEditorProps> = ({ heading, bulletList, blockquote, content, limit = 400, video, image, link, onChange, placeholder, error, disabled = false }, ref: RefObject<FabTextEditorRef>) => {
  const { t } = useTranslation('shared');
  const placeholderText = placeholder || t('app.shared.text_editor.fab_text_editor.text_placeholder');
  // TODO: Add ctrl+click on link to visit

  const editorRef: React.MutableRefObject<Editor | null> = useRef(null);
  // the methods in useImperativeHandle are exposed to the parent component
  useImperativeHandle(ref, () => ({
    focus () {
      editorRef.current?.commands?.focus();
    }
  }), []);

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
      Iframe,
      Image.configure({
        HTMLAttributes: {
          class: 'fab-text-editor-image'
        }
      })
    ],
    content,
    onUpdate: ({ editor }) => {
      onChange(editor.getHTML());
    }
  });

  useEffect(() => {
    editor?.setEditable(!disabled);
  }, [disabled]);

  useEffect(() => {
    if (editor?.getHTML() !== content) {
      editor?.commands.setContent(content);
    }
  }, [content]);

  // bind the editor to the ref, once it is ready
  if (!editor) return null;
  editorRef.current = editor;

  return (
    <div className={`fab-text-editor ${disabled && 'is-disabled'}`}>
      <MenuBar editor={editor} heading={heading} bulletList={bulletList} blockquote={blockquote} video={video} image={image} link={link} disabled={disabled} />
      <EditorContent editor={editor} />
      <div className="fab-text-editor-character-count">
        {editor?.storage.characterCount.characters()} / {limit}
      </div>
      {error &&
        <div className="fab-text-editor-error">
          <WarningOctagon size={24} />
          <p className="">{error}</p>
        </div>
      }
    </div>
  );
};

// eslint-disable-next-line import/no-default-export
export default forwardRef(FabTextEditor);
