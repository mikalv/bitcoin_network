defmodule BitcoinNetwork.Protocol.Message do
  defstruct magic: nil, command: nil, size: nil, checksum: nil, payload: nil

  alias BitcoinNetwork.Protocol
  alias BitcoinNetwork.Protocol.{Message, Version}

  def parse(binary) do
    with <<
           magic::32-little,
           command::binary-size(12),
           size::32-little,
           checksum::32-big,
           payload::binary-size(size),
           rest::binary
         >> <- binary do
      {:ok,
       %Message{
         magic: magic,
         command:
           command
           |> :binary.bin_to_list()
           |> Enum.reject(&(&1 == 0))
           |> :binary.list_to_bin(),
         size: size,
         checksum: checksum,
         payload: parse_payload(command, payload)
       }, rest}
    else
      _ -> nil
    end
  end

  def parse_payload("version", payload) do
    Version.parse(payload)
  end

  def parse_payload(_, payload), do: payload

  def serialize(command, payload \\ <<>>)

  def serialize(command, payload) when is_binary(payload) do
    Protocol.serialize(%Message{
      command: command,
      payload: payload
    })
  end

  def serialize(command, payload) do
    Protocol.serialize(%Message{
      command: command,
      payload: Protocol.serialize(payload)
    })
  end

  def verify_checksum(%Message{size: size, checksum: checksum, payload: payload}) do
    checksum(payload) == checksum && byte_size(payload) == size
  end

  def verify_checksum(_), do: false

  def checksum(payload) do
    <<checksum::32, _::binary>> =
      payload
      |> hash(:sha256)
      |> hash(:sha256)

    checksum
  end

  defp hash(data, algorithm), do: :crypto.hash(algorithm, data)
end

defimpl BitcoinNetwork.Protocol, for: BitcoinNetwork.Protocol.Message do
  alias BitcoinNetwork.Protocol.Message

  def serialize(%Message{command: command, payload: payload}) do
    <<
      Application.get_env(:bitcoin_network, :magic)::binary,
      String.pad_trailing(command, 12, <<0>>)::binary,
      byte_size(payload)::32-little,
      :binary.encode_unsigned(Message.checksum(payload))::binary,
      payload::binary
    >>
  end
end
