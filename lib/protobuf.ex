defmodule ParadigmInterop.Protobuf do
  def create_protobuf_graph(file_node_id, contents) do
    # TODO get rid of file_node_id pass thru
    {:ok, desc_contents} = compile_proto_to_desc(file_node_id, contents)

    {:ok, %Protox.Definition{messages_schemas: messages} = protobuf_definition} =
      Protox.Parse.parse(desc_contents)

    IO.inspect(messages)
    false
  end

  defp compile_proto_to_desc(proto_path, content) do
    # Create temp directory for both input and output
    temp_dir = System.tmp_dir!()
    temp_proto_path = Path.join(temp_dir, Path.basename(proto_path))
    desc_filename = Path.basename(proto_path, ".proto") <> ".desc"
    desc_path = Path.join(temp_dir, desc_filename)

    with :ok <- File.write(temp_proto_path, content),
         true <- File.exists?(temp_proto_path),
         {_output, 0} <-
           System.cmd("protoc", [
             "--proto_path=#{temp_dir}",
             "--descriptor_set_out=#{desc_path}",
             "--include_imports",
             Path.basename(proto_path)
           ]) do
      File.read(desc_path)
    else
      {:error, reason} ->
        # Clean up on error
        File.rm(temp_proto_path)
        {:error, "Failed to write temp proto file: #{inspect(reason)}"}

      {error_output, exit_code} ->
        # Clean up on error
        File.rm(temp_proto_path)
        {:error, "protoc failed with exit code #{exit_code}: #{error_output}"}
    end
  rescue
    e in ErlangError ->
      {:error, "protoc command not found: #{inspect(e)}"}
  end
end
