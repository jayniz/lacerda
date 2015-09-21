This gem needs to do N things:

1) Compare one json schema (X:provides:Y) to the other (Z:consumes:Y)
   to see if what X provides satisfies the needs of Z
2) Check all published messages of X against the json schema X:provides:Y
3) Check all property reads of received and consumed messages of Z
   and only allow access to what's defined in the json schema Z:consumes:Y
4) Know about all participating repositories

For now, it should do 1 and 4 first, as it is environment/programming
language agnostic. Then, 2 and 3 should be tackled.
