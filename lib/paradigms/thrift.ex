defmodule ParadigmInterop.Paradigms.Thrift do
  @moduledoc false
  alias Paradigm.{Package, Class, Property, PrimitiveType}

  def definition do
    %Paradigm{
      name: "Thrift",
      description: "Paradigm model for Apache Thrift IDL",
      primitive_types: %{
        "boolean" => %PrimitiveType{name: "Boolean"},
        "integer" => %PrimitiveType{name: "Integer"},
        "string" => %PrimitiveType{name: "String"}
      },
      packages: %{
        "thrift_package" => %Package{
          name: "thrift",
          uri: "http://example.org/thrift",
          nested_packages: [],
          owned_types: [
            "service",
            "method",
            "struct",
            "field",
            "enum",
            "enum_value",
            "primitive",
            "type",
            "union"
          ]
        }
      },
      classes: %{
        "service" => %Class{
          name: "Service",
          is_abstract: false,
          owned_attributes: ["service_name", "service_methods"],
          super_classes: []
        },
        "method" => %Class{
          name: "Method",
          is_abstract: false,
          owned_attributes: [
            "method_name",
            "method_return_type",
            "method_parameters",
            "method_throws"
          ],
          super_classes: []
        },
        "struct" => %Class{
          name: "Struct",
          is_abstract: false,
          owned_attributes: ["struct_fields"],
          super_classes: ["type"]
        },
        "union" => %Class{
          name: "Union",
          is_abstract: false,
          owned_attributes: ["union_fields"],
          super_classes: ["type"]
        },
        "primitive" => %Class{
          name: "Primitive",
          is_abstract: false,
          owned_attributes: [],
          super_classes: ["type"]
        },
        "field" => %Class{
          name: "Field",
          is_abstract: false,
          owned_attributes: [
            "field_name",
            "field_type",
            "field_required",
            "field_default",
            "field_is_list"
          ],
          super_classes: []
        },
        "enum" => %Class{
          name: "Enum",
          is_abstract: false,
          owned_attributes: ["enum_values"],
          super_classes: ["type"]
        },
        "enum_value" => %Class{
          name: "EnumValue",
          is_abstract: false,
          owned_attributes: ["enum_value_name", "enum_value_value"],
          super_classes: []
        },
        "type" => %Class{
          name: "Type",
          is_abstract: false,
          owned_attributes: ["type_name"],
          super_classes: []
        }
      },
      properties: %{
        "service_name" => %Property{
          name: "name",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "service_methods" => %Property{
          name: "methods",
          type: "method",
          is_ordered: true,
          is_composite: true,
          lower_bound: 0,
          upper_bound: :infinity
        },
        "method_name" => %Property{
          name: "name",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "method_return_type" => %Property{
          name: "return_type",
          type: "type",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "method_parameters" => %Property{
          name: "parameters",
          type: "field",
          is_ordered: true,
          is_composite: true,
          lower_bound: 0,
          upper_bound: :infinity
        },
        "method_throws" => %Property{
          name: "throws",
          type: "field",
          is_ordered: true,
          is_composite: true,
          lower_bound: 0,
          upper_bound: :infinity
        },
        "struct_fields" => %Property{
          name: "fields",
          type: "field",
          is_ordered: true,
          is_composite: true,
          lower_bound: 0,
          upper_bound: :infinity
        },
        "union_fields" => %Property{
          name: "fields",
          type: "field",
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
        "field_required" => %Property{
          name: "required",
          type: "boolean",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "field_default" => %Property{
          name: "default",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 0,
          upper_bound: 1
        },
        "field_is_list" => %Property{
          name: "is_list",
          type: "boolean",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
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
        "enum_value_name" => %Property{
          name: "name",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "enum_value_value" => %Property{
          name: "value",
          type: "integer",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "type_name" => %Property{
          name: "name",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        }
      },
      enumerations: %{}
    }
  end

  def inject_primitive_nodes(graph) do
    primitive_types = ~w(string i32 i64 bool double byte binary)

    Enum.reduce(primitive_types, graph, fn type, acc ->
      Map.put_new(acc, type, %Paradigm.Graph.Node{
        class: "primitive",
        data: %{"name" => type}
      })
    end)
  end
end
