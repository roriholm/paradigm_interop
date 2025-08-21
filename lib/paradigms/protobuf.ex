defmodule ParadigmInterop.Paradigms.Protobuf do
  @moduledoc false
  alias Paradigm.{Package, Class, Property, PrimitiveType}

  def definition do
    %Paradigm{
      name: "Protobuf",
      description: "Protocol Buffers data model",
      primitive_types: %{
        "integer" => %PrimitiveType{name: "Integer"},
        "string" => %PrimitiveType{name: "String"}
      },
      packages: %{
        "protobuf_package" => %Package{
          name: "protobuf",
          uri: "http://example.org/protobuf",
          nested_packages: [],
          owned_types: ["message", "field", "enum", "enum_value"]
        }
      },
      classes: %{
        "type" => %Class{
          name: "Type",
          is_abstract: true,
          owned_attributes: ["type_name"],
          super_classes: []
        },
        "primitive" => %Class{
          name: "Primitive",
          is_abstract: false,
          owned_attributes: [],
          super_classes: ["type"]
        },
        "message" => %Class{
          name: "Message",
          is_abstract: false,
          owned_attributes: ["message_fields", "nested_messages"],
          super_classes: ["type"]
        },
        "field" => %Class{
          name: "Field",
          is_abstract: false,
          owned_attributes: ["field_name", "field_type", "field_tag", "field_label"],
          super_classes: []
        },
        "enum" => %Class{
          name: "Enum",
          is_abstract: false,
          owned_attributes: ["enum_values", "parent_message"],
          super_classes: ["type"]
        },
        "enum_value" => %Class{
          name: "EnumValue",
          is_abstract: false,
          owned_attributes: ["enum_value_name", "enum_value_number"],
          super_classes: []
        }
      },
      properties: %{
        "type_name" => %Property{
          name: "name",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "message_fields" => %Property{
          name: "fields",
          type: "field",
          is_ordered: true,
          is_composite: true,
          lower_bound: 0,
          upper_bound: :infinity
        },
        "nested_messages" => %Property{
          name: "nested_messages",
          type: "message",
          is_ordered: true,
          is_composite: true,
          lower_bound: 0,
          upper_bound: :infinity
        },
        "field_name" => %Property{
          name: "name",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "field_type" => %Property{
          name: "type",
          type: "type",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "field_tag" => %Property{
          name: "tag",
          type: "integer",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "field_label" => %Property{
          name: "label",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 0,
          upper_bound: 1
        },
        "enum_values" => %Property{
          name: "values",
          type: "enum_value",
          is_ordered: true,
          is_composite: true,
          lower_bound: 0,
          upper_bound: :infinity
        },
        "parent_message" => %Property{
          name: "parent",
          type: "message",
          is_ordered: false,
          is_composite: false,
          lower_bound: 0,
          upper_bound: 1
        },
        "enum_value_name" => %Property{
          name: "name",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "enum_value_number" => %Property{
          name: "number",
          type: "integer",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        }
      },
      enumerations: %{}
    }
  end
end
