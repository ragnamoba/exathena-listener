# Used by "mix format"
locals_without_parens = [
  # Router
  packet: 2,

  # Packet
  defpacket: 2,
  rule: 3
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
