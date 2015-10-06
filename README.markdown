# Minimum term

This shall be a framework so that in each of our services one can define what messages it publishes and what messages it consumes. That way when changing what one service publishes or consumes, one cann immediately see the effects on our other services.

## This gem needs to do N things:

1. Convert [MSON](https://github.com/apiaryio/mson) into [JSON
   Schema](http://json-schema.org/)
2. Compare one json schema (X:provides:Y) to the other (Z:consumes:Y) to see if what X provides satisfies the needs of Z
3. Know about all participating repositories
4. Provide a test runner that, when making changes to project X, tests if the changes are compatible with all other participating repositories
5. Validate published messages against the schema on the fly
6. Validate consumed messages against the schema on the fly

## Prerequesites

Most of the stuff happens in the `/ruby` directory right now.
Go there, and

  - install drafter via `brew install --HEAD
    https://raw.github.com/apiaryio/drafter/master/tools/homebrew/drafter.rb`
  - run `bundle`
  - run `guard` in a spare terminal which will run the tests,
    install gems, and so forth


Example contracts are kept in the `/contracts` dir for now but will be fetched from the participating projects' repositories later.

## Convert MSON to JSON Schema files

First, check out [this API Blueprint map](https://github.com/apiaryio/api-blueprint/wiki/API-Blueprint-Map) to understand how _API Blueprint_ documents are laid out:

![API Blueprint map](https://raw.githubusercontent.com/apiaryio/api-blueprint/master/assets/map.png)

You can see that their structure covers a full API use case with resource groups, single resources, actions on those resources including requests and responses. All we want, though, is the little red top level branch called `Data structures`.

In theory, we'd use a ruby gem called [RedSnow](https://github.com/apiaryio/redsnow), which has bindings to [SnowCrash](https://github.com/apiaryio/snowcrash) which parses _API Blueprints_ into an AST. Unfortunately, RedSnow ignores that red `Data structures` branch we want (SnowCrash parses it just fine).

So for now, we use a command line tool called [drafter](https://github.com/apiaryio/drafter) to convert MSON into an _API Blueprint_ AST. From that AST we pic the `Data structures` entry and convert it into [JSON Schema]()s

Luckily, a rake task does all that for you. To convert all `*.mson` files in `contracts` into `*.schema.json` files, call:

```shell
➜  minimum-term/ruby $ rake mson_to_json_schema
✅  /Users/jannis/Dev/core/minimum-term/contracts/author/consume.mson
✅  /Users/jannis/Dev/core/minimum-term/contracts/author/publish.mson
✅  /Users/jannis/Dev/core/minimum-term/contracts/edward/consume.mson
➜  minimum-term/ruby $
```
