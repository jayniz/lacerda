# Lacerda [![Circle CI](https://circleci.com/gh/moviepilot/lacerda/tree/master.svg?style=shield)](https://circleci.com/gh/moviepilot/lacerda/tree/master) [![Coverage Status](https://coveralls.io/repos/moviepilot/lacerda/badge.svg?branch=master&service=github)](https://coveralls.io/github/moviepilot/lacerda?branch=master) [![Code Climate](https://codeclimate.com/github/moviepilot/lacerda/badges/gpa.svg)](https://codeclimate.com/github/moviepilot/lacerda) [![Dependency Status](https://gemnasium.com/moviepilot/lacerda.svg)](https://gemnasium.com/moviepilot/lacerda) [![Gem Version](https://badge.fury.io/rb/lacerda.svg)](https://badge.fury.io/rb/lacerda)

![](https://dl.dropboxusercontent.com/u/1953503/lacerda.jpg)
> «No, no -- we have to go on. We need total coverage.»<sup>[1](#references)</sup>

This gem can:

- convert MSON to JSON Schema files
- read a directory which contains one directory per service
- read a publish.mson and a consume.mson from each service
- build a model of your infrastructure knowing
  - which services publishes what to which other service
  - which service consumes what from which other service
  - if all services consume and publish conforming to their contracts.

You likely **don't want to use it on its own** but integrate your infrastructure via

⏩[Zeta](https://github.com/moviepilot/zeta) ⏪

. Click the link, it will explains things in more detail. If you're just looking for *one* way to transform MSON files into JSON Schema, read on:

## MSON to JSON schema
*Lacerda* offers a rake task that converts MSON files into JSON schemas.
To convert all `*.mson` files in `contracts/` into `*.schema.json` files,

put this in your `Rakefile`:

```ruby
require "lacerda/tasks"
```

and smoke it:

```shell
/home/dev/lacerda$ DATA_DIR=contracts/ rake lacerda:mson_to_json_schema
Converting 4 files:
OK /home/dev/lacerda/specifications/consumer/consume.mson
OK /home/dev/lacerda/specifications/invalid_property/consume.mson
OK /home/dev/lacerda/specifications/missing_required/consume.mson
OK /home/dev/lacerda/specifications/publisher/publish.mson
/home/dev/lacerda$
```

## Structure

By loading all files in a directory this gem will build up the following
relationships:

- Infrastructure
  - Service
    - Contracts
      - Publish specification
        - PublishedObjects
      - Consume specification
        - ConsumedObjects

## Compatibility

Until there is a native MSON to JSON schema parser available, we do the
conversion ourselves. These features from the MSON specification are currently supported:

- [x] primitive properties: `string`, `number`, `boolean`, `null`
- [x] `object` properties
- [x] `array` properties with items of one type
- [x] `array` properties of mixed types
- [ ] `array` properties of arrays
- [x] `enum` properties
- [x] `One of` properties mutually exclusive properties
- [x] `Referencing`
- [ ] `Mixins` 
- [ ] Variable property names


## Tests and development
  - run `bundle` once
  - run `guard` in a spare terminal which will run the tests,
    install gems, and so forth
  - run `rspec spec` to run all the tests
  - check out  `open coverage/index.html` or `open coverage/rcov/index.html`
  - run `bundle console` to play around with a console

# References
[1] This quote in French quotation marks is from "Fear and Loathing in Las Vegas". Since I can't link to the book, a link to the [movie script](http://www.dailyscript.com/scripts/fearandloathing.html) shall suffice.
