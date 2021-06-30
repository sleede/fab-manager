import React, { useState } from 'react';
import { IFablab } from '../../models/fablab';
import { FabInput } from '../base/fab-input';
import { FabButton } from '../base/fab-button';
import { Price } from '../../models/price';
import FormatLib from '../../lib/format';

declare var Fablab: IFablab;

interface EditablePriceProps {
  price: Price,
  onSave: (price: Price) => void,
}

/**
 * Display the given price.
 * When the user clics on the price, switch to the edition mode to allow him modifying the price.
 */
export const EditablePrice: React.FC<EditablePriceProps> = ({ price, onSave }) => {
  const [edit, setEdit] = useState<boolean>(false);
  const [tempPrice, setTempPrice] = useState<string>(`${price.amount}`);

  /**
   * Saves the new price
   */
  const handleValidateEdit = (): void => {
    const newPrice: Price = Object.assign({}, price);
    newPrice.amount = parseFloat(tempPrice);
    onSave(newPrice);
    toggleEdit();
  }

  /**
   * Enable or disable the edit mode
   */
  const toggleEdit = (): void => {
    setEdit(!edit);
  }

  return (
    <span className="editable-price">
      {!edit && <span className="display-price" onClick={toggleEdit}>{FormatLib.price(price.amount)}</span>}
      {edit && <span>
        <FabInput id="price" type="number" step={0.01} defaultValue={price.amount} addOn={Fablab.intl_currency} onChange={setTempPrice} required/>
        <FabButton icon={<i className="fas fa-check" />} className="approve-button" onClick={handleValidateEdit} />
        <FabButton icon={<i className="fas fa-times" />} className="cancel-button" onClick={toggleEdit} />
      </span>}
    </span>
  );
}
