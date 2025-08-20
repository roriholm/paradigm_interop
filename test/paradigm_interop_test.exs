defmodule ParadigmInteropTest do
  use ExUnit.Case
  doctest ParadigmInterop

  test "protobuf parsing and conformance" do
    {:ok, contents} = File.read("./test/data/vehicle_model/vehicle.proto")
    proto_graph = ParadigmInterop.Protobuf.create_protobuf_graph(contents)
    protobuf_paradigm = ParadigmInterop.Paradigms.Protobuf.definition()

    assert Paradigm.Conformance.check_graph(protobuf_paradigm, proto_graph) ==
             %Paradigm.Conformance.Result{issues: []}
  end

  test "avro parsing and conformance" do
    {:ok, contents} = File.read("./test/data/vehicle_model/vehicle.avsc")
    avro_graph = ParadigmInterop.Avro.create_avro_graph(contents)
    avro_paradigm = ParadigmInterop.Paradigms.Avro.definition()

    assert Paradigm.Conformance.check_graph(avro_paradigm, avro_graph) ==
             %Paradigm.Conformance.Result{issues: []}
  end

  test "schemas" do
    filesystem_graph = Paradigm.Graph.FilesystemGraph.new(root: "./test/data/vehicle_model")

    {:ok, schema_graph} =
      ParadigmInterop.Transforms.ParseSchemas.transform(
        filesystem_graph,
        Paradigm.Graph.MapGraph.new(),
        %{}
      )

    # schema_paradigm = ParadigmInterop.Paradigms.Schema.definition()

    # assert %Paradigm.Conformance.Result{issues: []} =
    #         Paradigm.Conformance.check_graph(schema_paradigm, schema_graph)
  end
end
