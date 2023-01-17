import { useEffect, useState } from 'react';
import * as React from 'react';
import { SubmitHandler, useFieldArray, useForm, useWatch } from 'react-hook-form';
import { Event, EventDecoration, EventPriceCategoryAttributes, RecurrenceOption } from '../../models/event';
import EventAPI from '../../api/event';
import { useTranslation } from 'react-i18next';
import { FormInput } from '../form/form-input';
import { FormImageUpload } from '../form/form-image-upload';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { ErrorBoundary } from '../base/error-boundary';
import { FormRichText } from '../form/form-rich-text';
import { FormMultiFileUpload } from '../form/form-multi-file-upload';
import { FabButton } from '../base/fab-button';
import { FormSwitch } from '../form/form-switch';
import { SelectOption } from '../../models/select';
import EventCategoryAPI from '../../api/event-category';
import { FormSelect } from '../form/form-select';
import EventThemeAPI from '../../api/event-theme';
import { FormMultiSelect } from '../form/form-multi-select';
import AgeRangeAPI from '../../api/age-range';
import { Plus, Trash } from 'phosphor-react';
import FormatLib from '../../lib/format';
import EventPriceCategoryAPI from '../../api/event-price-category';
import SettingAPI from '../../api/setting';
import { UpdateRecurrentModal } from './update-recurrent-modal';
import { AdvancedAccountingForm } from '../accounting/advanced-accounting-form';

declare const Application: IApplication;

interface EventFormProps {
  action: 'create' | 'update',
  event?: Event,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

/**
 * Form to edit or create events
 */
export const EventForm: React.FC<EventFormProps> = ({ action, event, onError, onSuccess }) => {
  const { handleSubmit, register, control, setValue, formState } = useForm<Event>({ defaultValues: { ...event } });
  const output = useWatch<Event>({ control });
  const { fields, append, remove } = useFieldArray({ control, name: 'event_price_categories_attributes' });

  const { t } = useTranslation('admin');

  const [isAllDay, setIsAllDay] = useState<boolean>(event?.all_day);
  const [categoriesOptions, setCategoriesOptions] = useState<Array<SelectOption<number>>>([]);
  const [themesOptions, setThemesOptions] = useState<Array<SelectOption<number>>>(null);
  const [ageRangeOptions, setAgeRangeOptions] = useState<Array<SelectOption<number>>>(null);
  const [priceCategoriesOptions, setPriceCategoriesOptions] = useState<Array<SelectOption<number>>>(null);
  const [isOpenRecurrentModal, setIsOpenRecurrentModal] = useState<boolean>(false);
  const [updatingEvent, setUpdatingEvent] = useState<Event>(null);
  const [isActiveAccounting, setIsActiveAccounting] = useState<boolean>(false);

  useEffect(() => {
    EventCategoryAPI.index()
      .then(data => setCategoriesOptions(data.map(m => decorationToOption(m))))
      .catch(onError);
    EventThemeAPI.index()
      .then(data => setThemesOptions(data.map(t => decorationToOption(t))))
      .catch(onError);
    AgeRangeAPI.index()
      .then(data => setAgeRangeOptions(data.map(r => decorationToOption(r))))
      .catch(onError);
    EventPriceCategoryAPI.index()
      .then(data => setPriceCategoriesOptions(data.map(c => decorationToOption(c))))
      .catch(onError);
    SettingAPI.get('advanced_accounting').then(res => setIsActiveAccounting(res.value === 'true')).catch(onError);
  }, []);

  /**
   * Callback triggered when the user clicks on the 'remove' button, in the additional prices area
   */
  const handlePriceRemove = (price: EventPriceCategoryAttributes, index: number) => {
    if (!price.id) return remove(index);

    setValue(`event_price_categories_attributes.${index}._destroy`, true);
  };

  /**
   * Callback triggered when the user validates the machine form: handle create or update
   */
  const onSubmit: SubmitHandler<Event> = (data: Event) => {
    if (action === 'update') {
      if (event?.recurrence_events?.length > 0) {
        setUpdatingEvent(data);
        toggleRecurrentModal();
      } else {
        handleUpdateRecurrentConfirmed(data, 'single');
      }
    } else {
      EventAPI.create(data).then(res => {
        onSuccess(t(`app.admin.event_form.${action}_success`));
        window.location.href = `/#!/events/${res.id}`;
      }).catch(onError);
    }
  };

  /**
   * Open/closes the confirmation modal for updating recurring events
   */
  const toggleRecurrentModal = () => {
    setIsOpenRecurrentModal(!isOpenRecurrentModal);
  };

  /**
   * Check if any dates have changed
   */
  const datesHaveChanged = (): boolean => {
    return ((event?.start_date !== (updatingEvent?.start_date as Date)?.toISOString()?.substring(0, 10)) ||
            (event?.end_date !== (updatingEvent?.end_date as Date)?.toISOString()?.substring(0, 10)));
  };

  /**
   * When the user has confirmed the update of the other occurences (or not), proceed with the API update
   * and handle the result
   */
  const handleUpdateRecurrentConfirmed = (data: Event, mode: 'single' | 'next' | 'all') => {
    EventAPI.update(data, mode).then(res => {
      if (res.total === res.updated) {
        onSuccess(t('app.admin.event_form.events_updated', { COUNT: res.updated }));
      } else {
        onError(t('app.admin.event_form.events_not_updated', { TOTAL: res.total, COUNT: res.total - res.updated }));
        if (res.details.events.find(d => d.error === 'EventPriceCategory')) {
          onError(t('app.admin.event_form.error_deleting_reserved_price'));
        } else {
          onError(t('app.admin.event_form.other_error'));
        }
      }
      window.location.href = '/#!/events';
    }).catch(onError);
  };

  /**
   * Convert an event-decoration (category/theme/etc.) to an option usable by react-select
   */
  const decorationToOption = (item: EventDecoration): SelectOption<number> => {
    return { value: item.id, label: item.name };
  };

  /**
   * In 'create' mode, the user can choose if the new event will be recurrent.
   * This method provides teh various options for recurrence
   */
  const buildRecurrenceOptions = (): Array<SelectOption<RecurrenceOption>> => {
    return [
      { label: t('app.admin.event_form.recurring.none'), value: 'none' },
      { label: t('app.admin.event_form.recurring.every_days'), value: 'day' },
      { label: t('app.admin.event_form.recurring.every_week'), value: 'week' },
      { label: t('app.admin.event_form.recurring.every_month'), value: 'month' },
      { label: t('app.admin.event_form.recurring.every_year'), value: 'year' }
    ];
  };

  return (
    <div className="event-form">
      <header>
        <h2>{t('app.admin.event_form.ACTION_title', { ACTION: action })}</h2>
        <FabButton onClick={handleSubmit(onSubmit)} className="fab-button save-btn is-main">
          {t('app.admin.event_form.save')}
        </FabButton>
      </header>
      <form className="event-form-content" onSubmit={handleSubmit(onSubmit)}>
        <section>
          <header>
            <p className="title">{t('app.admin.event_form.description')}</p>
          </header>
          <div className="content">
            <FormInput register={register}
                       id="title"
                       formState={formState}
                       rules={{ required: true }}
                       label={t('app.admin.event_form.title')} />
            <FormImageUpload setValue={setValue}
                             register={register}
                             control={control}
                             formState={formState}
                             rules={{ required: true }}
                             id="event_image_attributes"
                             accept="image/*"
                             defaultImage={output.event_image_attributes}
                             label={t('app.admin.event_form.matching_visual')} />
            <FormRichText control={control}
                          id="description"
                          rules={{ required: true }}
                          label={t('app.admin.event_form.description')}
                          limit={null}
                          heading bulletList blockquote link video image />
            <FormSelect id="category_id"
                        control={control}
                        formState={formState}
                        label={t('app.admin.event_form.event_category')}
                        options={categoriesOptions}
                        rules={{ required: true }} />
            {themesOptions?.length > 0 && <FormMultiSelect control={control}
                                                           id="event_theme_ids"
                                                           formState={formState}
                                                           options={themesOptions}
                                                           label={t('app.admin.event_form.event_themes')} />}
            {ageRangeOptions?.length > 0 && <FormSelect control={control}
                                                        id="age_range_id"
                                                        formState={formState}
                                                        options={ageRangeOptions}
                                                        label={t('app.admin.event_form.age_range')} />}
          </div>
        </section>

        <section>
          <header>
            <p className='title'>{t('app.admin.event_form.dates_and_opening_hours')}</p>
          </header>
          <div className="content">
            <div className="grp">
              <FormInput id="start_date"
                        type="date"
                        register={register}
                        formState={formState}
                        label={t('app.admin.event_form.start_date')}
                        rules={{ required: true }} />
              <FormInput id="end_date"
                        type="date"
                        register={register}
                        formState={formState}
                        label={t('app.admin.event_form.end_date')}
                        rules={{ required: true }} />
            </div>
            <FormSwitch control={control}
                      id="all_day"
                      label={t('app.admin.event_form.all_day')}
                      formState={formState}
                      tooltip={t('app.admin.event_form.all_day_help')}
                      onChange={setIsAllDay} />
            {!isAllDay && <div className="grp">
              <FormInput id="start_time"
                        type="time"
                        register={register}
                        formState={formState}
                        label={t('app.admin.event_form.start_time')}
                        rules={{ required: !isAllDay }} />
              <FormInput id="end_time"
                        type="time"
                        register={register}
                        formState={formState}
                        label={t('app.admin.event_form.end_time')}
                        rules={{ required: !isAllDay }} />
            </div>}
            {action === 'create' && <div className="grp">
              <FormSelect options={buildRecurrenceOptions()}
                          control={control}
                          formState={formState}
                          id="recurrence"
                          valueDefault="none"
                          label={t('app.admin.event_form.recurrence')} />
              <FormInput register={register}
                        id="recurrence_end_at"
                        type="date"
                        formState={formState}
                        nullable
                        defaultValue={null}
                        label={t('app.admin.event_form._and_ends_on')}
                        rules={{ required: !['none', undefined].includes(output.recurrence) }} />
            </div>}
          </div>
        </section>

        <section>
          <header>
            <p className="title">{t('app.admin.event_form.prices_and_availabilities')}</p>
          </header>
          <div className="content">
            <FormInput register={register}
                      id="nb_total_places"
                      label={t('app.admin.event_form.seats_available')}
                      type="number"
                      tooltip={t('app.admin.event_form.seats_help')} />
            <FormInput register={register}
                      id="amount"
                      formState={formState}
                      rules={{ required: true }}
                      label={t('app.admin.event_form.standard_rate')}
                      tooltip={t('app.admin.event_form.0_equal_free')}
                      addOn={FormatLib.currencySymbol()} />

            {priceCategoriesOptions && <div className="additional-prices">
              {fields.map((price, index) => (
                <div key={index} className={`price-item ${output.event_price_categories_attributes && output.event_price_categories_attributes[index]?._destroy ? 'destroyed-item' : ''}`}>
                  <FormSelect options={priceCategoriesOptions}
                              control={control}
                              id={`event_price_categories_attributes.${index}.price_category_id`}
                              rules={{ required: true }}
                              label={t('app.admin.event_form.fare_class')} />
                  <FormInput id={`event_price_categories_attributes.${index}.amount`}
                            register={register}
                            type="number"
                            rules={{ required: true }}
                            label={t('app.admin.event_form.price')}
                            addOn={FormatLib.currencySymbol()} />
                  <FabButton className="remove-price is-main" onClick={() => handlePriceRemove(price, index)} icon={<Trash size={20} />} />
                </div>
              ))}
              <FabButton className="add-price is-secondary" onClick={() => append({})}>
                <Plus size={20} />
                {t('app.admin.event_form.add_price')}
              </FabButton>
            </div>}
          </div>
        </section>

        <section>
          <header>
            <p className="title">{t('app.admin.event_form.attachments')}</p>
          </header>
          <div className="content">
            <div className='form-item-header machine-files-header'>
              <p>{t('app.admin.event_form.attached_files_pdf')}</p>
            </div>
            <FormMultiFileUpload setValue={setValue}
                                 addButtonLabel={t('app.admin.event_form.add_a_new_file')}
                                 control={control}
                                 accept="application/pdf"
                                 register={register}
                                 id="event_files_attributes"
                                 className="event-files" />
          </div>
        </section>

        {isActiveAccounting &&
          <section>
            <AdvancedAccountingForm register={register} onError={onError} />
          </section>
        }

        <UpdateRecurrentModal isOpen={isOpenRecurrentModal}
                              toggleModal={toggleRecurrentModal}
                              event={updatingEvent}
                              onConfirmed={handleUpdateRecurrentConfirmed}
                              datesChanged={datesHaveChanged()} />
      </form>
    </div>
  );
};

const EventFormWrapper: React.FC<EventFormProps> = (props) => {
  return (
    <Loader>
      <ErrorBoundary>
        <EventForm {...props} />
      </ErrorBoundary>
    </Loader>
  );
};

Application.Components.component('eventForm', react2angular(EventFormWrapper, ['action', 'event', 'onError', 'onSuccess']));
