import React from 'react';

interface FabOutputCopyProps {
  text: string,
  onCopy?: () => void,
  label?: string,
}

/**
 * This component shows a read-only input text filled with the provided text. A button allows to copy the text to the clipboard.
 */
export const FabOutputCopy: React.FC<FabOutputCopyProps> = ({ label, text, onCopy }) => {
  const [copied, setCopied] = React.useState(false);
  /**
   * Copy the given text to the clipboard.
   */
  const textToClipboard = () => {
    if (navigator && navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text);
      if (typeof onCopy === 'function') onCopy();
      setCopied(true);
      setTimeout(() => setCopied(false), 1000);
    }
  };

  return (
    <div className="fab-output-copy">
      <label className="form-item">
        <div className='form-item-header'>
          <p>{label}</p>
        </div>
        <div className='form-item-field'>
          <input value={text} readOnly />
          <span className="addon">
            <button className={copied ? 'copied' : ''} onClick={textToClipboard}><i className="fa fa-clipboard" /></button>
          </span>
        </div>
      </label>
    </div>
  );
};
