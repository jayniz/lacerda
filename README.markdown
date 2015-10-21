# Minimum term

This shall be a framework so that in each of our services one can define what messages it publishes and what messages it consumes. That way when changing what one service publishes or consumes, one can immediately see the effects on our other services.


## Prerequesites

  - install drafter via `brew install --HEAD
    https://raw.github.com/apiaryio/drafter/master/tools/homebrew/drafter.rb`
  - run `bundle`

## Tests and development
  - run `guard` in a spare terminal which will run the tests,
    install gems, and so forth
  - run `rspec spec` to run all the tests
  - check out  `open coverage/index.html` or `open coverage/rcov/index.html`
  - run `bundle console` to play around with a console

## Structure
- Infrastructure
  - Service
    - Contracts
      - Publish contract
        - PublishedObjects
      - Consume contract
        - ConsumedObjects


## Convert MSON to JSON Schema files
First, check out [this API Blueprint map](https://github.com/apiaryio/api-blueprint/wiki/API-Blueprint-Map) to understand how _API Blueprint_ documents are laid out:

![API Blueprint map](https://raw.githubusercontent.com/apiaryio/api-blueprint/master/assets/map.png)

You can see that their structure covers a full API use case with resource groups, single resources, actions on those resources including requests and responses. All we want, though, is the little red top level branch called `Data structures`.

In theory, we'd use a ruby gem called [RedSnow](https://github.com/apiaryio/redsnow), which has bindings to [SnowCrash](https://github.com/apiaryio/snowcrash) which parses _API Blueprints_ into an AST. Unfortunately, RedSnow ignores that red `Data structures` branch we want (SnowCrash parses it just fine).

So for now, we use a command line tool called [drafter](https://github.com/apiaryio/drafter) to convert MSON into an _API Blueprint_ AST. From that AST we pic the `Data structures` entry and convert it into [JSON Schema]()s

Luckily, a rake task does all that for you. To convert all `*.mson` files in `contracts/` into `*.schema.json` files,

put this in your `Rakefile`:

```ruby
require "minimum-term/tasks"
```

and smoke it:

```shell
/home/dev/minimum-term$ DATA_DIR=contracts/ rake minimum_term:mson_to_json_schema
Converting 4 files:
OK /home/dev/minimum-term/contracts/consumer/consume.mson
OK /home/dev/minimum-term/contracts/invalid_property/consume.mson
OK /home/dev/minimum-term/contracts/missing_required/consume.mson
OK /home/dev/minimum-term/contracts/publisher/publish.mson
/home/dev/minimum-term$
```
