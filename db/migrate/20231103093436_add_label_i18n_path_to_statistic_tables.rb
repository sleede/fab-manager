class AddLabelI18nPathToStatisticTables < ActiveRecord::Migration[7.0]
  def change
    add_column :statistic_indices, :label_i18n_path, :string
    add_column :statistic_types, :label_i18n_path, :string
    add_column :statistic_sub_types, :label_i18n_path, :string
    add_column :statistic_fields, :label_i18n_path, :string

    # StatisticIndex

    statistic_index_subscription = StatisticIndex.find_by!(es_type_key: 'subscription')
    statistic_index_subscription.update!(label: nil, label_i18n_path: 'statistics.subscriptions')

    statistic_index_machine = StatisticIndex.find_by!(es_type_key: 'machine')
    statistic_index_machine.update!(label: nil, label_i18n_path: 'statistics.machines_hours')

    statistic_index_training = StatisticIndex.find_by!(es_type_key: 'training')
    statistic_index_training.update!(label: nil, label_i18n_path: 'statistics.trainings')

    statistic_index_event = StatisticIndex.find_by!(es_type_key: 'event')
    statistic_index_event.update!(label: nil, label_i18n_path: 'statistics.events')

    statistic_index_account = StatisticIndex.find_by!(es_type_key: 'account')
    statistic_index_account.update!(label: nil, label_i18n_path: 'statistics.registrations')

    statistic_index_project = StatisticIndex.find_by!(es_type_key: 'project')
    statistic_index_project.update!(label: nil, label_i18n_path: 'statistics.projects')

    statistic_index_user = StatisticIndex.find_by!(es_type_key: 'user')
    statistic_index_user.update!(label: nil, label_i18n_path: 'statistics.users')

    statistic_index_space = StatisticIndex.find_by!(es_type_key: 'space')
    statistic_index_space.update!(label: nil, label_i18n_path: 'statistics.spaces')

    statistic_index_order = StatisticIndex.find_by!(es_type_key: 'order')
    statistic_index_order.update!(label: nil, label_i18n_path: 'statistics.orders')

    # StatisticField

    StatisticField.find_by!(key: 'groupName', statistic_index_id: statistic_index_subscription.id).update!(label: nil, label_i18n_path: 'statistics.group')

    StatisticField.find_by!(key: 'spaceDates', statistic_index_id: statistic_index_space.id).update!(label: nil, label_i18n_path: 'statistics.space_dates')
    StatisticField.find_by!(key: 'groupName', statistic_index_id: statistic_index_space.id).update!(label: nil, label_i18n_path: 'statistics.group')

    StatisticField.find_by!(key: 'machineDates', statistic_index_id: statistic_index_machine.id).update!(label: nil, label_i18n_path: 'statistics.machine_dates')
    StatisticField.find_by!(key: 'groupName', statistic_index_id: statistic_index_machine.id).update!(label: nil, label_i18n_path: 'statistics.group')


    StatisticField.find_by!(key: 'trainingId', statistic_index_id: statistic_index_training.id).update!(label: nil, label_i18n_path: 'statistics.training_id')
    StatisticField.find_by!(key: 'trainingDate', statistic_index_id: statistic_index_training.id).update!(label: nil, label_i18n_path: 'statistics.training_date')
    StatisticField.find_by!(key: 'groupName', statistic_index_id: statistic_index_training.id).update!(label: nil, label_i18n_path: 'statistics.group')

    StatisticField.find_by!(key: 'name', statistic_index_id: statistic_index_event.id).update!(label: nil, label_i18n_path: 'statistics.event_name')
    StatisticField.find_by!(key: 'eventId', statistic_index_id: statistic_index_event.id).update!(label: nil, label_i18n_path: 'statistics.event_id')
    StatisticField.find_by!(key: 'eventDate', statistic_index_id: statistic_index_event.id).update!(label: nil, label_i18n_path: 'statistics.event_date')
    StatisticField.find_by!(key: 'groupName', statistic_index_id: statistic_index_event.id).update!(label: nil, label_i18n_path: 'statistics.group')
    StatisticField.find_by!(key: 'eventTheme', statistic_index_id: statistic_index_event.id).update!(label: nil, label_i18n_path: 'statistics.event_theme')
    StatisticField.find_by!(key: 'ageRange', statistic_index_id: statistic_index_event.id).update!(label: nil, label_i18n_path: 'statistics.age_range')

    StatisticField.find_by!(key: 'groupName', statistic_index_id: statistic_index_account.id).update!(label: nil, label_i18n_path: 'statistics.group')

    StatisticField.find_by!(key: 'themes', statistic_index_id: statistic_index_project.id).update!(label: nil, label_i18n_path: 'statistics.themes')
    StatisticField.find_by!(key: 'components', statistic_index_id: statistic_index_project.id).update!(label: nil, label_i18n_path: 'statistics.components')
    StatisticField.find_by!(key: 'machines', statistic_index_id: statistic_index_project.id).update!(label: nil, label_i18n_path: 'statistics.machines')
    StatisticField.find_by!(key: 'status', statistic_index_id: statistic_index_project.id).update!(label: nil, label_i18n_path: 'statistics.project_status')
    StatisticField.find_by!(key: 'name', statistic_index_id: statistic_index_project.id).update!(label: nil, label_i18n_path: 'statistics.project_name')
    StatisticField.find_by!(key: 'projectUserNames', statistic_index_id: statistic_index_project.id).update!(label: nil, label_i18n_path: 'statistics.project_user_names')

    StatisticField.find_by!(key: 'userId', statistic_index_id: statistic_index_user.id).update!(label: nil, label_i18n_path: 'statistics.user_id')

    StatisticField.find_by!(key: 'groupName', statistic_index_id: statistic_index_order.id).update!(label: nil, label_i18n_path: 'statistics.group')

    # StatisticType
    StatisticType.find_by!(key: 'booking', statistic_index_id: statistic_index_machine.id).update!(label: nil, label_i18n_path: 'statistics.bookings')
    StatisticType.find_by!(key: 'hour', statistic_index_id: statistic_index_machine.id).update!(label: nil, label_i18n_path: 'statistics.hours_number')

    StatisticType.find_by!(key: 'booking', statistic_index_id: statistic_index_training.id).update!(label: nil, label_i18n_path: 'statistics.bookings')
    StatisticType.find_by!(key: 'hour', statistic_index_id: statistic_index_training.id).update!(label: nil, label_i18n_path: 'statistics.hours_number')

    StatisticType.find_by!(key: 'booking', statistic_index_id: statistic_index_event.id).update!(label: nil, label_i18n_path: 'statistics.tickets_number')
    StatisticType.find_by!(key: 'hour', statistic_index_id: statistic_index_event.id).update!(label: nil, label_i18n_path: 'statistics.hours_number')

    StatisticType.find_by!(key: 'member', statistic_index_id: statistic_index_account.id).update!(label: nil, label_i18n_path: 'statistics.users')

    StatisticType.find_by!(key: 'project', statistic_index_id: statistic_index_project.id).update!(label: nil, label_i18n_path: 'statistics.projects')

    StatisticType.find_by!(key: 'revenue', statistic_index_id: statistic_index_user.id).update!(label: nil, label_i18n_path: 'statistics.revenue')

    StatisticType.find_by!(key: 'booking', statistic_index_id: statistic_index_space.id).update!(label: nil, label_i18n_path: 'statistics.bookings')
    StatisticType.find_by!(key: 'hour', statistic_index_id: statistic_index_space.id).update!(label: nil, label_i18n_path: 'statistics.hours_number')

    StatisticType.find_by!(key: 'store', statistic_index_id: statistic_index_order.id).update!(label: nil, label_i18n_path: 'statistics.store')

    # StatisticSubType
    StatisticSubType.find_by!(key: 'created').update!(label: nil, label_i18n_path: 'statistics.account_creation')
    StatisticSubType.find_by!(key: 'published').update!(label: nil, label_i18n_path: 'statistics.project_publication')
    StatisticSubType.find_by!(key: 'paid-processed').update!(label: nil, label_i18n_path: 'statistics.paid-rocessed')
    StatisticSubType.find_by!(key: 'aborted').update!(label: nil, label_i18n_path: 'statistics.aborted')
  end
end
