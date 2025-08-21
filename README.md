# ParadigmInterop

This project is a meta-interoperability layer built on the `Paradigm` framework. It provides metamodels and utilities for working with Thrift, Avro, and Protobuf.

The goal of this library is to
* Characterize schemas that have universal representation between the 3 protocols via round-trip transforms to and from the `Metamodel` paradigm.
* Express protocol-specific extensions, capture any data loss, and suggest extensions to `Metamodel`.
* Provide code generation handles for each tool.

The top-level modules `ParadigmInterop.Thrift`, `ParadigmInterop.Protobuf`, `ParadigmInterop.Avro` wrap 3rd-party Elixir libraries and provide utilities for adapting their AST structs into Paradigm graphs conforming to `ParadigmInterop.Paradigms.Thrift` etc.

## Protobuf
Utilizes the [Protox](https://hexdocs.pm/protox/readme.html) library. The parsing module requires `protobuf` in the system path in order to convert `.proto` to `.desc`.

Missing
* Enumerations
* Maps
* Default Values

## Avro
Uses [AvroEx](https://hexdocs.pm/avro_ex/AvroEx.html).

## Thrift
Uses Pinterest's [Thrift](https://hexdocs.pm/thrift/readme.html) implementation.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `paradigm_interop` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:paradigm_interop, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/paradigm_interop>.
