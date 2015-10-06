# This gem needs to do N things:

1) Compare one json schema (X:provides:Y) to the other (Z:consumes:Y) to see if what X provides satisfies the needs of Z
2) Check all published messages of X against the json schema X:provides:Y
3) Check all property reads of received and consumed messages of Z and only allow access to what's defined in the json schema Z:consumes:Y
4) Know about all participating repositories

For now, it should do 1 and 4 first, as it is environment/programming language agnostic. Then, 2 and 3 should be tackled.

## Convert MSON to JSON Schema files

We use  [drafter](https://github.com/apiaryio/drafter) to convert MSON to JSON Schema, because Redsnow seems to only like fully fledged apiary documents, and not just MSON. You can install it via `brew install --HEAD \
  https://raw.github.com/apiaryio/drafter/master/tools/homebrew/drafter.rb`

Then, you can convert all `*.mson` files in `contracts` using `rake
mson_to_json_schema`.

## Code

Most of the stuff happens in the `/ruby` directory right now.
Go there, and

  - run `bundle`
  - run `guard` in a spare terminal which will run the tests,
    install gems, and so forth


Example contracts are kept in the `/contracts` dir for now but
will be fetched from the participating projects' repositories
later.
