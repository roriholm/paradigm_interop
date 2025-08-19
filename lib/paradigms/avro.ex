defmodule ParadigmInterop.Paradgms.Avro do
  @moduledoc false
  alias Paradigm.{Package, Class, Property, PrimitiveType}

  def definition do
    %Paradigm{
      name: "Avro",
      description: "Paradigm model for Apache Avro data format",
      primitive_types: %{
        "boolean" => %PrimitiveType{name: "Boolean"},
        "integer" => %PrimitiveType{name: "Integer"},
        "string" => %PrimitiveType{name: "String"}
      },
      packages: %{
        "avro_package" => %Package{
          name: "avro",
          uri: "http://avro.apache.org/schema/1.9.0",
          nested_packages: [],
          owned_types: ["record", "enum", "fixed", "array", "map", "primitive", "field"]
        }
      },
      classes: %{
        "record" => %Class{
          name: "Record",
          is_abstract: false,
          owned_attributes: [
            "record_name",
            "record_namespace",
            "record_doc",
            "record_aliases",
            "record_fields"
          ],
          super_classes: ["type"]
        },
        "enum" => %Class{
          name: "Enum",
          is_abstract: false,
          owned_attributes: [
            "enum_name",
            "enum_namespace",
            "enum_doc",
            "enum_aliases",
            "enum_symbols"
          ],
          super_classes: ["type"]
        },
        "fixed" => %Class{
          name: "Fixed",
          is_abstract: false,
          owned_attributes: ["fixed_name", "fixed_namespace", "fixed_aliases", "fixed_size"],
          super_classes: ["type"]
        },
        "array" => %Class{
          name: "Array",
          is_abstract: false,
          owned_attributes: ["array_items"],
          super_classes: ["type"]
        },
        "map" => %Class{
          name: "Map",
          is_abstract: false,
          owned_attributes: ["map_values"],
          super_classes: ["type"]
        },
        "primitive" => %Class{
          name: "Primitive",
          is_abstract: false,
          owned_attributes: [],
          super_classes: ["type"]
        },
        "type" => %Class{
          name: "Type",
          is_abstract: true,
          owned_attributes: ["type_name"],
          super_classes: []
        },
        "field" => %Class{
          name: "Field",
          is_abstract: false,
          owned_attributes: [
            "field_name",
            "field_type",
            "field_doc",
            "field_default",
            "field_aliases"
          ],
          super_classes: []
        }
      },
      properties: %{
        "record_name" => %Property{
          name: "name",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "record_namespace" => %Property{
          name: "namespace",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 0,
          upper_bound: 1
        },
        "record_doc" => %Property{
          name: "doc",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 0,
          upper_bound: 1
        },
        "record_aliases" => %Property{
          name: "aliases",
          type: "string",
          is_ordered: true,
          is_composite: false,
          lower_bound: 0,
          upper_bound: :infinity
        },
        "record_fields" => %Property{
          name: "fields",
          type: "field",
          is_ordered: true,
          is_composite: true,
          lower_bound: 0,
          upper_bound: :infinity
        },
        "enum_name" => %Property{
          name: "name",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "enum_namespace" => %Property{
          name: "namespace",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 0,
          upper_bound: 1
        },
        "enum_doc" => %Property{
          name: "doc",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 0,
          upper_bound: 1
        },
        "enum_aliases" => %Property{
          name: "aliases",
          type: "string",
          is_ordered: true,
          is_composite: false,
          lower_bound: 0,
          upper_bound: :infinity
        },
        "enum_symbols" => %Property{
          name: "symbols",
          type: "string",
          is_ordered: true,
          is_composite: false,
          lower_bound: 1,
          upper_bound: :infinity
        },
        "fixed_name" => %Property{
          name: "name",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "fixed_namespace" => %Property{
          name: "namespace",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 0,
          upper_bound: 1
        },
        "fixed_aliases" => %Property{
          name: "aliases",
          type: "string",
          is_ordered: true,
          is_composite: false,
          lower_bound: 0,
          upper_bound: :infinity
        },
        "fixed_size" => %Property{
          name: "size",
          type: "integer",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "array_items" => %Property{
          name: "items",
          type: "type",
          is_ordered: false,
          is_composite: false,
          lower_bound: 1,
          upper_bound: 1
        },
        "map_values" => %Property{
          name: "values",
          type: "type",
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
        "field_doc" => %Property{
          name: "doc",
          type: "string",
          is_ordered: false,
          is_composite: false,
          lower_bound: 0,
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
        "field_aliases" => %Property{
          name: "aliases",
          type: "string",
          is_ordered: true,
          is_composite: false,
          lower_bound: 0,
          upper_bound: :infinity
        }
      },
      enumerations: %{}
    }
  end

  def inject_primitive_nodes(graph) do
    primitive_types = ~w(null boolean int long float double bytes string)

    Enum.reduce(primitive_types, graph, fn type, acc ->
      Map.put_new(acc, type, %Paradigm.Graph.Node{
        class: "primitive",
        data: %{"name" => type}
      })
    end)
  end
end
