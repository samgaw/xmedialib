### ----------------------------------------------------------------------
###
### Heavily modified version of Peter Lemenkov's STUN encoder. Big ups go to him
### for his excellent work in this area.
###
### @maintainer: Lee Sylvester <lee.sylvester@gmail.com>
###
### Copyright (c) 2012 Peter Lemenkov <lemenkov@gmail.com>
###
### Copyright (c) 2013 - 2019 Lee Sylvester and Xirsys LLC <experts@xirsys.com>
###
### All rights reserved.
###
### XMediaLib is licensed by Xirsys, with permission, under the Apache
### License Version 2.0. (the "License");
### you may not use this file except in compliance with the License.
### You may obtain a copy of the License at
###
###      http://www.apache.org/licenses/LICENSE-2.0
###
### Unless required by applicable law or agreed to in writing, software
### distributed under the License is distributed on an "AS IS" BASIS,
### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
### See the License for the specific language governing permissions and
### limitations under the License.
###
### See LICENSE for the full license text.
###
### ----------------------------------------------------------------------

defmodule XMediaLib.Stun do
  use Bitwise
  require Logger
  alias XMediaLib.Stun

  @moduledoc """
  The XMediaLib.Stun module provides the RFC 5389 implementation of the STUN protocol for both encoding and decoding.
  """

  # Used by the STUN specification RFC 5389 to tag a packet as
  # specifically of a STUN format.
  @stun_marker 0
  @stun_magic_cookie 0x2112A442

  @doc """
  STUN object structure for per-connection usage
  """
  defstruct class: nil,
            method: nil,
            transactionid: nil,
            integrity: false,
            key: nil,
            fingerprint: true,
            attrs: [],
            # Xirsys account namespace
            ns: nil,
            # Xirsys peer id (user implementation specific)
            peer_id: nil

  @doc """
  Accepts a STUN binary stream and attempts to convert it to readable
  packets for use by the greater application.
  ## Example
        iex> request = <<0, 1, 0, 0, 33, 18, 164, 66, 0, 146, 225, 0,
        ...> 61, 62, 163, 87, 45, 150, 223, 8>>
        iex> XMediaLib.Stun.decode(request)
        {:ok, %Stun{attrs: [], class: :request, fingerprint: false,
        integrity: false, key: nil, method: :binding,
        transactionid: 177565706535525809372192520}}
  """
  def decode(stun_binary, key \\ nil) do
    {fingerprint, rest} = check_fingerprint(stun_binary)
    {integrity, rest2} = check_integrity(rest, key)
    process_stun(rest2, key, fingerprint, integrity)
  end

  def process_stun(stun_binary, key, fingerprint, integrity) do
    <<@stun_marker::2, m0::5, c0::1, m1::3, c1::1, m2::4, length::16, @stun_magic_cookie::32,
      transactionid::96, rest3::binary>> = stun_binary

    method = get_method(<<m0::size(5), m1::size(3), m2::size(4)>>)
    class = get_class(<<c0::size(1), c1::size(1)>>)
    attrs = decode_attrs(rest3, length, transactionid)

    {:ok,
     %XMediaLib.Stun{
       class: class,
       method: method,
       integrity: integrity,
       key: key,
       transactionid: transactionid,
       fingerprint: fingerprint,
       attrs: attrs
     }}
  end

  @doc """
  Accepts data and attempts to convert it to a STUN specific
  stream as a response to the calling client.
  ## Example
        iex> response = %Stun{class: :success, method: :binding,
        ...> transactionid: 123456789012, fingerprint: false, attrs: %{
        ...>   xor_mapped_address: {{127,0,0,1}, 12345},
        ...>   mapped_address: {{127,0,0,1}, 12345},
        ...>   source_address: {{127,0,0,1}, 12346},
        ...>   software: <<"XMediaLib-stun">>
        ...> }
        iex> XMediaLib.Stun.encode(response)
        <<1, 1, 0, 52, 33, 18, 164, 66, 0, 0, 0, 0, 0, 0, 0, 28, 190, 153,
        26, 20, 0, 32, 0, 8, 0, 1, 17, 43, 94, 18, 164, 67, 0, 1, 0, 8, 0,
        1, 48, 57, 127, 0, 0, 1, 0, 4, 0, 8, 0, 1, 48, 58, 127, 0, 0, 1,
        128, 34, 0, 11, 120, 105, 114, 115, 121, 115, 45, 115, 116, 117,
        110, 0>>
  """
  def encode(%XMediaLib.Stun{} = config) do
    # Logger.info "STUN_CONN #{inspect config}"
    m = get_method_id(config.method)
    <<m0::size(5), m1::size(3), m2::size(4)>> = <<m::size(12)>>
    <<c0::size(1), c1::size(1)>> = get_class_id(config.class)

    bin_attrs =
      for {t, v} <- config.attrs,
          into: "",
          do: encode_bin(encode_attribute(t, v, config.transactionid))

    length = byte_size(bin_attrs)

    <<@stun_marker::size(2), m0::size(5), c0::size(1), m1::size(3), c1::size(1), m2::size(4),
      length::size(16), @stun_magic_cookie::size(32), config.transactionid::size(96),
      bin_attrs::binary>>
    |> maybe_insert_integrity(config)
    |> maybe_insert_fingerprint(config)
  end

  # -------------------------------------------------------------------------------
  # Start code generation
  # -------------------------------------------------------------------------------

  @external_resource attrs_path = Path.join([__DIR__, "../priv/turn-attrs.txt"])
  @external_resource methods_path = Path.join([__DIR__, "../priv/turn-methods.txt"])
  @external_resource classes_path = Path.join([__DIR__, "../priv/turn-classes.txt"])

  # Encodes an attribute tuple into a new tuple representing its type and
  # an encoded binary representation of its value
  for line <- File.stream!(attrs_path, [], :line) do
    [byte, name, type] = line |> String.split("\t") |> Enum.map(&String.trim(&1))

    case type do
      "value" ->
        defp decode_attribute(unquote(String.to_integer(byte)), value, _),
          do: {String.to_atom(unquote(name)), value}

        defp encode_attribute(unquote(String.to_atom(name)), value, _),
          do: {String.to_integer(unquote(byte)), value}

      "attribute" ->
        defp decode_attribute(unquote(String.to_integer(byte)), value, _),
          do: {String.to_atom(unquote(name)), decode_attr_addr(value)}

        defp encode_attribute(unquote(String.to_atom(name)), value, _),
          do: {String.to_integer(unquote(byte)), encode_attr_addr(value)}

      "xattribute" ->
        defp decode_attribute(unquote(String.to_integer(byte)), value, tid),
          do: {String.to_atom(unquote(name)), decode_attr_xaddr(value, tid)}

        defp encode_attribute(unquote(String.to_atom(name)), value, tid),
          do: {String.to_integer(unquote(byte)), encode_attr_xaddr(value, tid)}

      "error_attribute" ->
        defp decode_attribute(unquote(String.to_integer(byte)), value, _),
          do: {String.to_atom(unquote(name)), decode_attr_err(value)}

        defp encode_attribute(unquote(String.to_atom(name)), value, _),
          do: {String.to_integer(unquote(byte)), encode_attr_err(value)}

      "request" ->
        defp decode_attribute(unquote(String.to_integer(byte)), value, _),
          do: {String.to_atom(unquote(name)), decode_change_req(value)}

        defp encode_attribute(unquote(String.to_atom(name)), value, _),
          do: {String.to_integer(unquote(byte)), encode_change_req(value)}
    end
  end

  defp decode_attribute(byte, value, _) do
    Logger.error("Could not find match for #{inspect(byte)}")
    {byte, value}
  end

  defp encode_attribute(other, value, _) do
    Logger.error("Could not find match for #{inspect(other)}")
    {other, value}
  end

  # Provides packet method type based on id and vice versa
  for line <- File.stream!(methods_path, [], :line) do
    [id, name] = line |> String.split("\t") |> Enum.map(&String.trim(&1))

    defp get_method(<<unquote(String.to_integer(id))::size(12)>>),
      do: unquote(String.to_atom(name))

    defp get_method_id(unquote(String.to_atom(name))),
      do: unquote(String.to_integer(id))
  end

  defp get_method(<<o::size(12)>>),
    do: o

  defp get_method_id(o),
    do: o

  # Provides packet class type based on id and vice versa
  for line <- File.stream!(classes_path, [], :line) do
    [id, name] = line |> String.split("\t") |> Enum.map(&String.trim(&1))

    defp get_class(<<unquote(String.to_integer(id))::size(2)>>),
      do: unquote(String.to_atom(name))

    defp get_class_id(unquote(String.to_atom(name))),
      do: <<unquote(String.to_integer(id))::2>>
  end

  # -------------------------------------------------------------------------------
  # End code generation
  # -------------------------------------------------------------------------------

  #####
  # STUN decoding helpers

  # Converts a given binary encoded list of attributes into an Erlang list of tuples
  defp decode_attrs(pkt, len, tid, attrs \\ %{})

  defp decode_attrs(<<>>, 0, _, attrs) do
    attrs
  end

  defp decode_attrs(<<>>, length, _, attrs) do
    Logger.info("STUN TLV wrong length #{length}")
    attrs
  end

  defp decode_attrs(<<type::size(16), item_length::size(16), bin::binary>>, length, tid, attrs) do
    whole_pkt? = item_length == byte_size(bin)

    padding_length =
      case rem(item_length, 4) do
        0 -> 0
        _other when whole_pkt? -> 0
        other -> 4 - other
      end

    <<value::binary-size(item_length), _::binary-size(padding_length), rest::binary>> = bin
    {t, v} = decode_attribute(type, value, tid)
    new_length = length - (2 + 2 + item_length + padding_length)
    decode_attrs(rest, new_length, tid, Map.put(attrs, t, v))
  end

  # Converts a given binary encoded IPv4 address into an Erlang tuple
  defp decode_attr_addr(
         <<0::size(8), 1::size(8), port::size(16), i0::size(8), i1::size(8), i2::size(8),
           i3::size(8)>>
       ),
       do: {{i0, i1, i2, i3}, port}

  # Converts a given binary encoded IPv6 address into an Erlang tuple
  defp decode_attr_addr(
         <<0::size(8), 2::size(8), port::size(16), i0::size(16), i1::size(16), i2::size(16),
           i3::size(16), i4::size(16), i5::size(16), i6::size(16), i7::size(16)>>
       ),
       do: {{i0, i1, i2, i3, i4, i5, i6, i7}, port}

  # Converts a given XOR binary encoded IPv4 address into an Erlang tuple
  defp decode_attr_xaddr(<<0::size(8), 1::size(8), xport::size(16), xaddr::size(32)>>, _) do
    port = bxor(xport, bsr(@stun_magic_cookie, 16))

    <<i0::size(8), i1::size(8), i2::size(8), i3::size(8)>> =
      <<bxor(xaddr, @stun_magic_cookie)::size(32)>>

    {{i0, i1, i2, i3}, port}
  end

  # Converts a given XOR binary encoded IPv6 address into an Erlang tuple
  defp decode_attr_xaddr(<<0::size(8), 2::size(8), xport::size(16), xaddr::size(128)>>, tid) do
    port = bxor(xport, bsr(@stun_magic_cookie, 16))

    <<i0::size(16), i1::size(16), i2::size(16), i3::size(16), i4::size(16), i5::size(16),
      i6::size(16),
      i7::size(16)>> = <<bxor(xaddr, bor(bsl(@stun_magic_cookie, 96), tid))::size(128)>>

    {{i0, i1, i2, i3, i4, i5, i6, i7}, port}
  end

  # Converts a given binary encoded error into an Erlang tuple
  defp decode_attr_err(<<_mbz::size(20), class::size(4), number::size(8), reason::binary>>),
    do: {class * 100 + number, reason}

  # Converts a given binary encoded change request into an Erlang tuple
  defp decode_change_req(<<_::size(29), change_ip::size(1), change_port::size(1), _::size(1)>>) do
    ip =
      case change_ip do
        1 -> [:ip]
        0 -> []
      end

    port =
      case change_port do
        1 -> [:port]
        0 -> []
      end

    ip ++ port
  end

  #####
  # Encoding helpers

  # Encodes an attribute tuple into its specific encoded binary
  defp encode_bin({t, v}) do
    l = byte_size(v)

    padding_length =
      case rem(l, 4) do
        0 -> 0
        other -> (4 - other) * 8
      end

    <<t::16, l::16, v::binary-size(l), 0::size(padding_length)>>
  end

  # Encodes an attribute IPv4 address tuple into its binary representation
  defp encode_attr_addr({{i0, i1, i2, i3}, port} = _args),
    do:
      <<0::size(8), 1::size(8), port::size(16), i0::size(8), i1::size(8), i2::size(8),
        i3::size(8)>>

  # Encodes an attribute IPv6 address tuple into its binary representation
  defp encode_attr_addr({{i0, i1, i2, i3, i4, i5, i6, i7}, port}),
    do:
      <<0::size(8), 2::size(8), port::size(16), i0::size(16), i1::size(16), i2::size(16),
        i3::size(16), i4::size(16), i5::size(16), i6::size(16), i7::size(16)>>

  # Encodes an attribute IPv4 address tuple into its XOR binary representation
  defp encode_attr_xaddr({{i0, i1, i2, i3}, port}, _) do
    xport = bxor(port, bsr(@stun_magic_cookie, 16))
    <<addr::size(32)>> = <<i0::size(8), i1::size(8), i2::size(8), i3::size(8)>>
    xaddr = bxor(addr, @stun_magic_cookie)
    <<0::size(8), 1::size(8), xport::size(16), xaddr::size(32)>>
  end

  # Encodes an attribute IPv6 address tuple into its XOR binary representation
  defp encode_attr_xaddr({{i0, i1, i2, i3, i4, i5, i6, i7}, port}, tid) do
    xport = bxor(port, bsr(@stun_magic_cookie, 16))

    <<addr::size(128)>> =
      <<i0::size(16), i1::size(16), i2::size(16), i3::size(16), i4::size(16), i5::size(16),
        i6::size(16), i7::size(16)>>

    xaddr = bxor(addr, bor(bsl(@stun_magic_cookie, 96), tid))
    <<0::size(8), 2::size(8), xport::size(16), xaddr::size(128)>>
  end

  # Encodes a STUN error tuple into its binary representation
  defp encode_attr_err({error_code, reason}) do
    class = div(error_code, 100)
    number = rem(error_code, 100)
    <<0::size(20), class::size(4), number::size(8), reason::binary>>
  end

  # Encodes a STUN change request tuple into its binary representation
  defp encode_change_req(list) do
    ip =
      case Keyword.has_key?(list, :ip) do
        true -> 1
        false -> 0
      end

    port =
      case Keyword.has_key?(list, :port) do
        true -> 1
        false -> 0
      end

    <<0::size(29), ip::size(1), port::size(1), 0::size(1)>>
  end

  #####
  # Fingerprinting and auth

  # Checks if a raw STUN binary contains a fingerprint (RFC 5389). If so, removes the
  # fingerprint and re-hashes ready for an integrity check (RFC 3489)
  defp check_fingerprint(stun_binary) do
    s = byte_size(stun_binary) - 8

    case stun_binary do
      <<message::binary-size(s), 0x80::8, 0x28::8, 0x00::8, 0x04::8, crc::32>> ->
        # Die if CRC doesn't match
        try do
          ^crc = bxor(:erlang.crc32(message), 0x5354554E)
          <<h::size(16), old_size::size(16), payload::binary>> = message
          new_size = old_size - 8
          {true, <<h::size(16), new_size::size(16), payload::binary>>}
        rescue
          _ -> {false, stun_binary}
        end

      _ ->
        Logger.debug("No CRC was found in a STUN message.")
        {false, stun_binary}
    end
  end

  # Applies a fingerprint (RFC 5389) to a STUN binary
  defp insert_fingerprint(stun_binary) do
    <<h::size(16), _::size(16), message::binary>> = stun_binary
    s = byte_size(stun_binary) + 8 - 20
    crc = bxor(:erlang.crc32(<<h::size(16), s::size(16), message::binary>>), 0x5354554E)

    <<h::size(16), s::size(16), message::binary, 0x80::size(8), 0x28::size(8), 0x00::size(8),
      0x04::size(8), crc::size(32)>>
  end

  defp maybe_insert_fingerprint(stun_binary, %Stun{} = config) do
    case config.fingerprint do
      false -> stun_binary
      true -> insert_fingerprint(stun_binary)
    end
  end

  # Checks for an integrity marker and its validity in a STUN binary (RFC 3489)
  # Must be called AFTER check_fingerprint due to forward RFC incompatibility

  # full check of integrity
  def check_integrity(stun_binary, nil), do: {false, stun_binary}

  def check_integrity(stun_binary, key) when byte_size(stun_binary) > 20 + 24 do
    s = byte_size(stun_binary) - 24

    case stun_binary do
      <<message::binary-size(s), 0x00::size(8), 0x08::size(8), 0x00::size(8), 0x14::size(8),
        fingerprint::binary-size(20)>> ->
        ^fingerprint = :crypto.hmac(:sha, key, message)
        <<h::size(16), old_size::size(16), payload::binary>> = message
        new_size = old_size - 24
        {true, <<h::size(16), new_size::size(16), payload::binary>>}

      _ ->
        Logger.info("No MESSAGE-INTEGRITY was found in STUN message.")
        {false, stun_binary}
    end
  end

  # Inserts a valid integrity marker and value to the end of a STUN binary (RFC 3489)
  defp insert_integrity(stun_binary, nil),
    do: stun_binary

  defp insert_integrity(stun_binary, key) do
    <<h::size(16), _::size(16), message::binary>> = stun_binary
    s = byte_size(stun_binary) + 24 - 20
    fingerprint = :crypto.hmac(:sha, key, <<h::size(16), s::size(16), message::binary>>)

    <<h::size(16), s::size(16), message::binary, 0x00::size(8), 0x08::size(8), 0x00::size(8),
      0x14::size(8), fingerprint::binary>>
  end

  defp maybe_insert_integrity(stun_binary, %Stun{key: key}),
    do: insert_integrity(stun_binary, key)

  defp maybe_insert_integrity(stun_binary, %Stun{}), do: stun_binary
end
