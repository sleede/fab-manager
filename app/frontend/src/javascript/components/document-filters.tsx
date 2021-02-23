/**
 * This component shows 3 input fields for filtering invoices/payment-schedules by reference, customer name and date
 */

import React, { useEffect, useState } from 'react';
import { LabelledInput } from './labelled-input';
import { useTranslation } from 'react-i18next';

interface DocumentFiltersProps {
  onFilterChange: (value: { reference: string, customer: string, date: Date }) => void
}

export const DocumentFilters: React.FC<DocumentFiltersProps> = ({ onFilterChange }) => {
  const { t } = useTranslation('admin');

  const [referenceFilter, setReferenceFilter] = useState('');
  const [customerFilter, setCustomerFilter] = useState('');
  const [dateFilter, setDateFilter] = useState(null);

  useEffect(() => {
    onFilterChange({ reference: referenceFilter, customer: customerFilter, date: dateFilter });
  }, [referenceFilter, customerFilter, dateFilter])

  const handleReferenceUpdate = (e) => {
    setReferenceFilter(e.target.value);
  }

  const handleCustomerUpdate = (e) => {
    setCustomerFilter(e.target.value);
  }

  const handleDateUpdate = (e) => {
    let date = e.target.value;
    if (e.target.value === '') date = null;
    setDateFilter(date);
  }

  return (
    <div className="document-filters">
      <LabelledInput id="reference"
                     label={t('app.admin.invoices.document_filters.reference')}
                     type="text"
                     onChange={handleReferenceUpdate}
                     value={referenceFilter} />
      <LabelledInput id="customer"
                     label={t('app.admin.invoices.document_filters.customer')}
                     type="text"
                     onChange={handleCustomerUpdate}
                     value={customerFilter} />
      <LabelledInput id="reference"
                     label={t('app.admin.invoices.document_filters.date')}
                     type="date"
                     onChange={handleDateUpdate}
                     value={dateFilter ? dateFilter : ''} />
    </div>
  );
}
