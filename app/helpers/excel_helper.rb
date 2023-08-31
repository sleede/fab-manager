# frozen_string_literal: true

# Helpers for excel exports, for use with AXSLX gem
module ExcelHelper
  # format the given source data for an Excell cell
  def format_xlsx_cell(source_data, data, styles, types, date_format: nil, source_data_type: '')
    case source_data_type
    when 'date'
      data.push Date.strptime(source_data, '%Y-%m-%d')
      styles.push date_format
      types.push :date
    when 'list'
      data.push source_data.map { |e| e['name'] }.join(', ')
      styles.push nil
      types.push :string
    when 'number'
      data.push source_data
      styles.push nil
      types.push :float
    else
      data.push source_data
      styles.push nil
      types.push :string
    end
  end

  # build a new excel line for a statistic export
  def statistics_line(hit, user, type, subtype, date_format)
    data = [
      Date.strptime(hit['_source']['date'], '%Y-%m-%d'),
      user&.profile&.full_name || t('export.deleted_user'),
      user&.email || '',
      user&.profile&.phone || '',
      t("export.#{hit['_source']['gender']}"),
      hit['_source']['age'],
      subtype.nil? ? '' : subtype.label
    ]
    styles = [date_format, nil, nil, nil, nil, nil, nil]
    types = %i[date string string string string integer string]
    # do not proceed with the 'stat' field if the type is declared as 'simple'
    unless type.simple
      data.push hit['_source']['stat']
      styles.push nil
      types.push :float
    end

    [data, styles, types]
  end

  def add_hardcoded_cells(index, hit, data, styles, types)
    if index.concerned_by_reservation_context?
      add_reservation_context_cell(hit, data, styles, types)
    end
  end

  def add_reservation_context_cell(hit, data, styles, types)
    reservation_contexts = ReservationContext.pluck(:id, :name).to_h

    data.push reservation_contexts[hit['_source']['reservationContextId']]
    styles.push nil
    types.push :text
  end

  # append a cell containing the CA amount
  def add_ca_cell(index, hit, data, styles, types)
    return unless index.ca

    data.push hit['_source']['ca']
    styles.push nil
    types.push :float
  end

  def add_coupon_cell(index, hit, data, styles, types)
    return unless index.show_coupon?

    data.push hit['_source']['coupon']
    styles.push nil
    types.push :text
  end

  ##
  # Retrieve an item in the given array of items
  # by default, the "id" is expected to match the given parameter but
  # this can be overridden by passing a third parameter to specify the
  # property to match
  ##
  def get_item(array, id, key = nil)
    array.each do |i|
      if key.nil?
        return i if i.id == id
      elsif i[key] == id
        return i
      end
    end
    nil
  end
end
