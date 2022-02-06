require "calculate_in_group/version"
require "calculate_in_group/railtie"

module CalculateInGroup
  module QueryMethods
    def calculate_in_group(operation_type, field, ranges = {}, options = {})
      raise ArgumentError.new("Operation #{operation_type} not supported. Try to use: :count, :average, :sum, :maximum, :minimum") if ![:count, :average, :sum, :maximum, :minimum].include?(operation_type.to_s.to_sym)
      raise ArgumentError.new("Column #{field} not found in `#{table_name}`") if !column_names.include?(field.to_s)

      table               = self.arel_table
      group_field         = "__#{field}"
      operation_attribute = "__#{operation_type}_all"
      query               = Arel::Nodes::Case.new
      conditions          = []

      ranges.each do |(k, v)|
        case v
        when Range
          a = table[field].gteq(v.begin) if v.begin
          b = table[field].lteq(v.end) if v.end
          c = [a, b].compact.inject(&:and)
        when Array
          c = table[field].in(v)
        else
          c = table[field].eq(v)
        end
        query = query.when(Arel.sql("(" + c.to_sql + ")#{__calculate_in_group_db_addon}")).then(k)
        conditions.push(where(field => v))
      end

      operation = if operation_type == :count
        Arel.star.count.as(operation_attribute)
      else
        table[field].send(operation_type).as(operation_attribute)
      end

      res = select([operation, query.as(group_field)])
      res = res.merge(conditions.inject(&:or)) if !options[:include_nil] && conditions.any?
      res = res.group(group_field)

      #puts res.to_sql

      res.inject({}) do |res, e|
        key = e.send(group_field)
        if key.nil? && options[:include_nil].present? && !!options[:include_nil] != options[:include_nil]
          key = options[:include_nil]
        end
        res[key] = e.send(operation_attribute)
        res
      end
    end

    private
    def __calculate_in_group_db_addon
      adapter_type = connection.adapter_name.downcase.to_sym
      case adapter_type
      when :mysql, :mysql2, :sqlite3, :sqlite
        nil # should work normally
      when :postgresql
        "::boolean"
      else
        raise NotImplementedError, "Unsupported adapter type '#{adapter_type}'"
      end
    end
  end

  module Relation
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.extend(CalculateInGroup::QueryMethods)
  ActiveRecord::Relation.include(CalculateInGroup::Relation)
end