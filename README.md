# easyseed

`easyseed` is designed around two entrypoints:

- `db/seeds.rb`, which still runs through the normal `rake db:seed` or `rails db:seed` flow;
- a spec seed file such as `spec/seeds.rb`, which your test suite can `load` after `DatabaseCleaner.clean`.

## Installation

Add the gem to your Rails app:

```ruby path=null start=null
gem "easyseed"
```

## `db/seeds.rb`

Replace the default `db/seeds.rb` with a thin wrapper:

```ruby path=null start=null
require "easyseed"

Easyseed.run!(
  :seed_path => "db/seeds",
  :allowed_environments => %w[test development]
)
```

That keeps the normal `db:seed` entrypoint in place while gating the seed run away from production.

Files inside `db/seeds` are loaded in this order:

1. `*.sql`
2. `*.csv`
3. `*.rb`
Within each file type, files are loaded in sorted filename order. If some seed files must run in a specific order, prefix them accordingly, such as `001_z.csv` and `002_a.csv`.

CSV filenames map to models with `classify.constantize`, so `users.csv` is loaded through `User`.
## Testing usage

### Dirty database testing

The most direct test usage follows the dirty-database approach: clean once, load a known seed set once, and let the suite run against that pre-populated database.
## `spec/seeds.rb` and `rails_helper`

For spec data, use the same API from a separate wrapper:

```ruby path=null start=null
require "easyseed"

Easyseed.run!(
  :seed_path => "spec/seeds",
  :allowed_environments => %w[test development]
)
```

Then keep the suite bootstrap in `rails_helper`:

```ruby path=null start=null
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean
    load(File.join(Rails.root, "spec/seeds.rb"))
  end
end
```

### Empty database testing

`easyseed` can also fit an empty-database style. In that setup, the suite starts clean by default and only the specs that want seeded data opt into it.

```ruby path=null start=null
RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner.clean
  end
end

RSpec.describe "seeded scenario" do
  before do
    Easyseed.run!(
      :seed_path => "spec/seeds/minimal",
      :allowed_environments => %w[test]
    )
  end
end
```

That keeps the general suite empty while still letting you maintain reusable file-based seed sets for targeted scenarios.

## PostgreSQL sequence reset

If the active adapter is PostgreSQL, `easyseed` automatically calls `reset_pk_sequence!` after SQL and CSV files finish loading.

Disable that behavior if needed:

```ruby path=null start=null
Easyseed.run!(
  :seed_path => "db/seeds",
  :allowed_environments => %w[test development],
  :sequence_reset => false
)
```

## `easyseed:init`

The gem ships with an `easyseed:init` task for bootstrapping an application:

```bash path=null start=null
bundle exec rake easyseed:init
```

It:

1. moves an existing `db/seeds.rb` to `db/seeds.rb.bak`;
2. writes an `easyseed` wrapper `db/seeds.rb`;
3. ensures `db/seeds` exists for the actual seed files;
4. adds `db/seeds/.gitkeep` and `db/seeds/readme.txt` with follow-up instructions.

If `db/seeds.rb` already contains `Easyseed.run!`, the task leaves it alone.

## API

```ruby path=null start=null
Easyseed.run!(
  :seed_path => "db/seeds",
  :allowed_environments => %w[test development],
  :root => Rails.root,
  :environment => Rails.env,
  :output => $stdout,
  :sequence_reset => :auto
)
```
