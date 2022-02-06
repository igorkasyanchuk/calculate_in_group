require "calculate_in_group/version"
require "calculate_in_group/railtie"

module CalculateInGroup
  module QueryMethods
    def calculate_in_group(operation_type, field, groups, options = {})
      # check if arguments are good
      raise ArgumentError.new("Please specify options for groups. Check the documentation") if groups.empty?
      raise ArgumentError.new("Operation #{operation_type} not supported. Try to use: :count, :average, :sum, :maximum, :minimum") if ![:count, :average, :sum, :maximum, :minimum].include?(operation_type.to_s.to_sym)
      raise ArgumentError.new("Column #{field} not found in `#{table_name}`") if !column_names.include?(field.to_s)
      raise ArgumentError.new("Groups `#{groups}` can be array or hash. Check the documentation") unless groups.is_a?(Array) || groups.is_a?(Hash)

      # init variables
      table               = self.arel_table
      group_field         = "__#{field}"
      operation_attribute = "__#{operation_type}_all"
      query               = Arel::Nodes::Case.new
      conditions          = []
      groupings           = groups.is_a?(Array) ? groups.inject({}) {|res, e| res[e.to_s] = e; res} : groups

      # build conditions
      groupings.each do |(k, v)|
        c = case v
        when Range
          # range could be endless, so we need to compact and build correct SQL for "between"
          a = table[field].gteq(v.begin) if v.begin
          if v.end
            b = if v.exclude_end? # e.g. 5...10 => [5,6,7,8,9]
              # [3] pry(#<CalculateInGroupTest>)> a = 0...10
              # a.to_a => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
              # [4] pry(#<CalculateInGroupTest>)> a.exclude_end?
              # => true
              table[field].lt(v.end)
            else
              # [1] pry(#<CalculateInGroupTest>)> a = 0..10
              # a.to_a => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
              # [2] pry(#<CalculateInGroupTest>)> a.exclude_end?
              # => false
              table[field].lteq(v.end) # e.g. 5..10 => [5,6,7,8,9,10]
            end
          end
          [a, b].compact.inject(&:and)
        when Array
          # SQL "IN"
          table[field].in(v)
        else
          # SQL "="
          table[field].eq(v)
        end
        query = query.when(Arel.sql("(" + c.to_sql + ")#{__calculate_in_group_db_addon}")).then(k)
        conditions.push(where(field => v))
      end

      # what we actually want to do? count, sum, average...., determine how we start SELECT ...
      operation = if operation_type == :count
        Arel.star.count.as(operation_attribute)
      else
        table[field].send(operation_type).as(operation_attribute)
      end

      # time to build query to DB
      # SELECT + WHERE + GROUP + OPERATION (sum, count, etc..)
      res = select([operation, query.as(group_field)])
      res = res.merge(conditions.inject(&:or)) if !options[:include_nil] && conditions.any?
      res = res.group(group_field)

      # process result from DB#
      # check if need to include "nil" value
      result = res.inject({}) do |res, e|
        key = e.send(group_field)
        if key.nil? && options[:include_nil].present? && !!options[:include_nil] != options[:include_nil] # not boolean, when option is a label
          key = options[:include_nil]
        end
        res[key] = e.send(operation_attribute)
        res
      end

      # check if we need to build full hash with all grouped fields
      if options.has_key?(:default_for_missing)
        (groupings.keys.map(&:to_s) - result.keys).each do |k|
          result[k] = options[:default_for_missing]
        end
      end

      # return :)
      result
    end

    private
    # this is needed for Postgres DB, it want's a bit different SQL in CASE statement
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

end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.extend(CalculateInGroup::QueryMethods)
end