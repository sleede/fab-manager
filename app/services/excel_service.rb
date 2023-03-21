# frozen_string_literal: true

# Provides methods around Excel files specification
class ExcelService
  class << self
    # remove all unauthorized characters from the given Excel's worksheet name
    # @param name [String]
    # @param replace [String]
    # @return [String]
    def name_safe(name, replace = '-')
      name.gsub(%r{[*|\\:"<>?/]}, replace).truncate(31)
    end

    # Generate a name for the current type, compatible with Excel worksheet names
    # @param type [StatisticType]
    # @param workbook [Axlsx::Workbook]
    # @return [String]
    def statistic_type_sheet_name(type, workbook)
      # see https://msdn.microsoft.com/fr-fr/library/c6bdca6y(v=vs.90).aspx for unauthorized character list
      name = "#{type.statistic_index.label} - #{type.label}".gsub(%r{[*|\\:"<>?/]}, '')
      # sheet name is limited to 31 characters
      if name.length > 31
        name = "#{type.statistic_index.label.truncate(4, omission: '.')} - #{type.label}".gsub(%r{[*|\\:"<>?/]}, '').truncate(31)
      end
      # we cannot have two sheets with the same name
      name = name[0..30] + String((rand * 10).to_i) until workbook.sheet_by_name(name).nil?
      name
    end
  end
end
