import React from 'react';
import { FabModal } from '../base/fab-modal';

interface TypeMappingModalProps {
  model: string,
  field: string,
  type: string,
  isOpen: boolean,
  toggleModal: () => void,
}

export const TypeMappingModal: React.FC<TypeMappingModalProps> = ({ model, field, type, isOpen, toggleModal }) => {
  return (
    <FabModal isOpen={isOpen} toggleModal={toggleModal}>
      <h1>{model}</h1>
      <h2>{field}</h2>
      <h3>{type}</h3>
    </FabModal>
  );
};
