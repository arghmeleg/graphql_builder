defmodule GraphqlBuilder do
  @moduledoc """
  Module conatining business logic for buiilding GraphQL queries and mutations.
  """

  alias GraphqlBuilder.Query

  @spec query(Query.t()) :: String.t()
  def query(%Query{operation: operation, fields: fields, variables: variables}) do
    indent_level = 2

    [
      query_keyword(),
      operation_and_variables(operation, variables),
      query_fields(fields, indent_level + 2, newline: true),
      indented_closing_brace(indent_level),
      indented_closing_brace(indent_level - 2)
    ]
    |> Enum.join()
  end

  @spec mutation(Query.t()) :: String.t()
  def mutation(%Query{
        operation: operation,
        fields: fields,
        variables: variables
      }) do
    indent_level = 2

    [
      mutation_keyword(),
      operation_and_variables(operation, variables),
      query_fields(fields, indent_level + 2, newline: true),
      indented_closing_brace(indent_level),
      indented_closing_brace(indent_level - 2)
    ]
    |> Enum.join()
  end

  @spec query_keyword :: String.t()
  defp query_keyword do
    "query {\n"
  end

  @spec mutation_keyword :: String.t()
  defp mutation_keyword do
    "mutation {\n"
  end

  @spec operation_and_variables(atom, [atom], keyword) :: String.t()
  defp operation_and_variables(operation, variables, opts \\ []) do
    indent_level = Keyword.get(opts, :indent_level, 2)

    indent(indent_level) <>
      "#{operation}" <>
      variable_list(variables) <>
      " {\n"
  end

  @spec indented_closing_brace(integer) :: String.t()
  defp indented_closing_brace(indent_level) do
    indent(indent_level) <> "}\n"
  end

  @spec query_fields([:atom], integer, keyword) :: String.t()
  defp query_fields(fields, indent_level, opts \\ []) do
    eol =
      if Keyword.get(opts, :newline, false) do
        "\n"
      else
        ""
      end

    if Enum.all?(fields, &is_atom/1) do
      fields
      |> Enum.map(&(indent(indent_level) <> "#{&1}"))
      |> Enum.join(",\n")
    else
      {field_string, _} = Enum.reduce(fields, {"", indent_level}, &process_nested_field/2)
      field_string
    end <>
      eol
  end

  @spec process_nested_field(atom, {String.t(), integer}) :: {String.t(), integer}
  defp process_nested_field(elem, {acc, indent_level}) when is_atom(elem) do
    {acc <> indent(indent_level) <> "#{elem},\n", indent_level}
  end

  defp process_nested_field({label, sub_fields}, {acc, indent_level}) do
    acc =
      acc <>
        indent(indent_level) <>
        "#{label} {\n" <>
        query_fields(sub_fields, indent_level + 2) <>
        "\n" <> indent(indent_level) <> "}"

    {acc, indent_level}
  end

  @spec variable_list([atom] | nil) :: String.t()
  defp variable_list(nil) do
    ""
  end

  defp variable_list(variables) do
    variables
    |> Enum.map(&variable/1)
    |> Enum.join(", ")
    |> (fn list -> "(#{list})" end).()
  end

  @spec variable({atom, atom | keyword}) :: String.t()
  defp variable({key, value}) do
    cond do
      is_binary(value) ->
        "#{key}: \"#{value}\""

      is_list(value) ->
        list = sub_variable_list(value)
        "#{key}: #{list}"

      true ->
        "#{key}: #{value}"
    end
  end

  @spec sub_variable_list([atom | keyword]) :: String.t()
  defp sub_variable_list(variables) do
    variables
    |> Enum.map(&variable/1)
    |> Enum.join(", ")
    |> (fn list -> "{#{list}}" end).()
  end

  @spec indent(integer) :: String.t()
  defp indent(n) do
    String.duplicate(" ", n)
  end
end
