import React, { SelectHTMLAttributes } from 'react';
import Select from 'react-select';
import { Controller } from 'react-hook-form';

interface FabSelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  className?: string
}

export const FabSelect: React.FC<FabSelectProps> = ({ className }) => {
  return (
    <div className={`fab-select ${className || ''}`}>
      <Controller name="description" control={control} render={({ field: { onChange, value } }) =>
        <Select defaultValue={defaultValues()}
                placeholder={t('app.shared.event.select_theme')}
                options={buildOptions()}
                isMulti />
      } />
    </div>
  );
};
