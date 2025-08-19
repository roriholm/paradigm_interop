defmodule ParadigmInterop.Paradigms.Schema do
  alias Paradigm.{Class, PrimitiveType, Property}

  def definition do
    %Paradigm{
      name: "Schema",
      description:
        "Container paradigm organizing raw schema ASTs from various formats that we have available in native Elixir.",
      primitive_types: %{
        "string" => %PrimitiveType{name: "String"},
        "thrift_ast" => %PrimitiveType{
          name: "Thrift.AST"
        },
        "protobuf_definition" => %PrimitiveType{
          name: "Protox.Definition"
        },
        "avro_schema" => %PrimitiveType{
          name: "AvroEx.Schema"
        }
      },
      classes: %{
        "schema_document" => %Class{
          name: "SchemaDocument",
          # description: "A parsed schema file with its raw AST",
          is_abstract: true,
          owned_attributes: ["source_path", "parse_metadata"]
        },
        "thrift_document" => %Class{
          name: "ThriftDocument",
          # description: "A Thrift schema document",
          super_classes: ["schema_document"],
          owned_attributes: ["thrift_ast"]
        },
        "protobuf_document" => %Class{
          name: "ProtobufDocument",
          # description: "A Protobuf schema document",
          super_classes: ["schema_document"],
          owned_attributes: ["protobuf_definition"]
        },
        "avro_document" => %Class{
          name: "AvroDocument",
          # description: "An Avro schema document",
          super_classes: ["schema_document"],
          owned_attributes: ["avro_schema"]
        }
      },
      properties: %{
        "source_path" => %Property{
          name: "source_path",
          type: "string"
          # description: "Original file path of the schema"
        },
        "parse_metadata" => %Property{
          name: "parse_metadata",
          type: "string"
          # description: "Metadata about parsing (timestamp, parser version, etc.)"
        },
        "thrift_ast" => %Property{
          name: "thrift_ast",
          type: "thrift_ast"
          # description: "Parsed Thrift AST structure"
        },
        "protobuf_definition" => %Property{
          name: "protobuf_definition",
          type: "protobuf_definition"
          # description: "Parsed Protobuf definition structure"
        },
        "avro_schema" => %Property{
          name: "avro_schema",
          type: "avro_schema"
          # description: "Parsed Avro schema structure"
        }
      }
    }
  end
end
