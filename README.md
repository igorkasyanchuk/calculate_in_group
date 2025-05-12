# calculate_in_group

[![RailsJazz](https://github.com/igorkasyanchuk/rails_time_travel/blob/main/docs/my_other.svg?raw=true)](https://www.railsjazz.com)
[![https://www.patreon.com/igorkasyanchuk](https://github.com/igorkasyanchuk/rails_time_travel/blob/main/docs/patron.svg?raw=true)](https://www.patreon.com/igorkasyanchuk)

[!["Buy Me A Coffee"](https://github.com/igorkasyanchuk/get-smart/blob/main/docs/snapshot-bmc-button-small.png?raw=true)](https://buymeacoffee.com/igorkasyanchuk)

Group ActiveRecord models with ranges. No more need to SQL with complex statements. Make your life easier :)

Can help with tasks like "I need to group users by age in different categories." or "I need to do some calculations for the reports/charts".

Easy to use, just add to Gemfile `gem "calculate_in_group"` and call `calculate_in_group` on your model.

Works with Postgres, MySQL, SQLite (at least on my computer). Also tried on production and works too, so I can consider it as production-ready.

## Usage

See below how to group your model by ranges or arrays and run aggregations for them in one SQL query.

```ruby
# Grouping can be used with :count, :average, :sum, :maximum, :minimum.

# Group with Ranges
User.calculate_in_group(:count, :age, [...10, 10...50, 50..] # => {"...10"=>1, "10...50"=>3, "50.."=>3}
User.calculate_in_group(:count, :created_at, { "old" => 12.hours.ago..1.minutes.ago, "new" => Time.now..10.hours.from_now }) # => {"old" => 2, "new" => 1}
User.calculate_in_group :count, :projects_count, [ 0, 1..5, 5..10, 10..100, 100.. ] # => {"0"=>555, "1..5"=>145, "10..100"=>3991, "100.."=>190, "5..10"=>2824} 

# Group with arrays or just values
User.calculate_in_group(:count, :role, "with_permissions" => ["admin", "moderator"], "no_permissions" => "user") # => {"with_permissions" => 3, "no_permissions" => 3}

# Other agg functions
User.calculate_in_group(:average, :age, "young" => 0..25, "old" => 60..100) # => {"young" => 11.0, "old" => 80.0}
User.calculate_in_group(:average, :age, "young" => 0..25, "old" => 60...100) # => {"young" => 11.0, "old" => 60.0}
User.calculate_in_group(:maximum, :age, "young" => 0..25, "old" => 60..100) # => {"young" => 20, "old" => 100}
User.calculate_in_group(:minimum, :age, "young" => 0..25, "old" => 60..100) # => {"young" => 3, "old" => 60}
User.calculate_in_group(:sum, :age, "young" => 0..25, "old" => 60..100) # => {"young" => 33, "old" => 160}
User.calculate_in_group(:sum, :age, {"young" => 0..25, "old" => 60..100}) # => {"young" => 33, "old" => 160}

# You can specify "other values" (with custom label) which are out of ranges
User.calculate_in_group(:count, :age, {"young" => 10, "average" => 25, "old" => 60}, {include_nil: "OTHER"}) # => {"young" => 1, "old" => 1, "OTHER" => 7}

# You can specify default value for keys which are missing in query
User.calculate_in_group(:count, :age, {"young" => 10, "average" => 25, "old" => 60}, { default_for_missing: 0 }) # => {"young" => 1, "old" => 1, "average" => 0}

# SEE MORE EXAMLES in test/calculate_in_group_test.rb
```

Options:

- `include_nil` (true or value)
- `default_for_missing` (default value for keys which are not returned by query)

Examples: https://github.com/igorkasyanchuk/calculate_in_group/blob/main/test/calculate_in_group_test.rb

PS: check my other gems here https://www.railsjazz.com/ or directly on github :)

## Installation

```ruby
gem "calculate_in_group"
```

And then execute:
```bash
$ bundle
```

## TODO

- try with more complex queries, joins, etc. and extend unit tests
- fix `rake test` command
- add Github Actions
- maybe support SQL for values? e.g. "date(current_year)"

## Testing

`ruby test/calculate_in_group_test.rb`.

Not sure, why rake test doesn't works for me :)

## Contributing

You are welcome to contribute or share your ideas.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

[<img src="https://github.com/igorkasyanchuk/rails_time_travel/blob/main/docs/more_gems.png?raw=true"
/>](https://www.railsjazz.com/?utm_source=github&utm_medium=bottom&utm_campaign=calculate_in_group)

[!["Buy Me A Coffee"](https://github.com/igorkasyanchuk/get-smart/blob/main/docs/snapshot-bmc-button.png?raw=true)](https://buymeacoffee.com/igorkasyanchuk)
