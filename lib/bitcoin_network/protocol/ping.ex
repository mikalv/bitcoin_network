defmodule BitcoinNetwork.Protocol.Ping do
  defstruct nonce: 0

  alias BitcoinNetwork.Protocol.Ping

  def parse(<<nonce::binary-size(8), rest::binary>>) do
    {:ok, %Ping{nonce: nonce}, rest}
  end

  def parse(<<>>) do
    {:ok, %Ping{}, <<>>}
  end
end

defimpl BitcoinNetwork.Protocol, for: BitcoinNetwork.Protocol.Ping do
  def serialize(ping) do
    <<ping.nonce::binary-size(8)>>
  end
end
