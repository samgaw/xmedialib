defmodule XMediaLib.StunTest do
  use ExUnit.Case
  use Bitwise
  alias XMediaLib.Stun

  @stun_bind_req_bin <<0, 1, 0, 16, 33, 18, 164, 66, 147, 49, 141, 31, 86, 17, 126, 65, 130, 38,
                       1, 0, 128, 34, 0, 12, 112, 106, 110, 97, 116, 104, 45, 49, 46, 52, 0, 0>>
  @stun_bind_req %Stun{
    class: :request,
    method: :binding,
    transactionid: 45_554_200_240_623_869_818_762_035_456,
    fingerprint: false,
    attrs: %{software: <<112, 106, 110, 97, 116, 104, 45, 49, 46, 52, 0, 0>>}
  }

  @stun_bind_req_bin_fixed <<0, 1, 0, 16, 33, 18, 164, 66, 147, 49, 141, 31, 86, 17, 126, 65, 130,
                             38, 1, 0, 128, 34, 0, 12, 112, 106, 110, 97, 116, 104, 45, 49, 46,
                             52, 0, 0>>
  @stun_bind_resp_bin <<1, 1, 0, 68, 33, 18, 164, 66, 147, 49, 141, 31, 86, 17, 126, 65, 130, 38,
                        1, 0, 0, 1, 0, 8, 0, 1, 224, 252, 88, 198, 53, 113, 0, 4, 0, 8, 0, 1, 13,
                        150, 208, 109, 222, 137, 0, 5, 0, 8, 0, 1, 13, 151, 208, 109, 222, 148,
                        128, 32, 0, 8, 0, 1, 193, 238, 121, 212, 145, 51, 128, 34, 0, 16, 86, 111,
                        118, 105, 100, 97, 46, 111, 114, 103, 32, 48, 46, 57, 54, 0>>
  @stun_bind_resp %Stun{
    class: :success,
    method: :binding,
    transactionid: 45_554_200_240_623_869_818_762_035_456,
    fingerprint: false,
    attrs: %{
      changed_address: {{208, 109, 222, 148}, 3479},
      mapped_address: {{88, 198, 53, 113}, 57596},
      software: <<86, 111, 118, 105, 100, 97, 46, 111, 114, 103, 32, 48, 46, 57, 54, 0>>,
      source_address: {{208, 109, 222, 137}, 3478},
      x_vovida_xor_mapped_address: {{88, 198, 53, 113}, 57596}
    }
  }
  @stun_bind_resp_bin_fixed <<1, 1, 0, 68, 33, 18, 164, 66, 147, 49, 141, 31, 86, 17, 126, 65,
                              130, 38, 1, 0, 0, 1, 0, 8, 0, 1, 224, 252, 88, 198, 53, 113, 0, 4,
                              0, 8, 0, 1, 13, 150, 208, 109, 222, 137, 0, 5, 0, 8, 0, 1, 13, 151,
                              208, 109, 222, 148, 128, 32, 0, 8, 0, 1, 193, 238, 121, 212, 145,
                              51, 128, 34, 0, 15, 86, 111, 118, 105, 100, 97, 46, 111, 114, 103,
                              32, 48, 46, 57, 54, 0>>

  test "Simple decoding of STUN Binding Request" do
    assert {:ok, @stun_bind_req} = Stun.decode(@stun_bind_req_bin)
  end

  test "Simple encoding of STUN Binding Request (with fixed length)" do
    assert @stun_bind_req_bin_fixed = Stun.encode(@stun_bind_req)
  end

  test "Simple decoding of STUN Binding Responce" do
    assert {:ok, @stun_bind_resp} = Stun.decode(@stun_bind_resp_bin)
  end

  test "Simple encoding of STUN Binding Responce (with fixed length)" do
    assert @stun_bind_resp_bin_fixed, Stun.encode(@stun_bind_resp)
  end

  @password "VOkJxbRl1RmTxUk/WvJxBt"

  @req_bin <<0x00, 0x01, 0x00, 0x58, 0x21, 0x12, 0xA4, 0x42, 0xB7, 0xE7, 0xA7, 0x01, 0xBC, 0x34,
             0xD6, 0x86, 0xFA, 0x87, 0xDF, 0xAE, 0x80, 0x22, 0x00, 0x10, 0x53, 0x54, 0x55, 0x4E,
             0x20, 0x74, 0x65, 0x73, 0x74, 0x20, 0x63, 0x6C, 0x69, 0x65, 0x6E, 0x74, 0x00, 0x24,
             0x00, 0x04, 0x6E, 0x00, 0x01, 0xFF, 0x80, 0x29, 0x00, 0x08, 0x93, 0x2F, 0xF9, 0xB1,
             0x51, 0x26, 0x3B, 0x36, 0x00, 0x06, 0x00, 0x09, 0x65, 0x76, 0x74, 0x6A, 0x3A, 0x68,
             0x36, 0x76, 0x59, 0x20, 0x20, 0x20, 0x00, 0x08, 0x00, 0x14, 0x9A, 0xEA, 0xA7, 0x0C,
             0xBF, 0xD8, 0xCB, 0x56, 0x78, 0x1E, 0xF2, 0xB5, 0xB2, 0xD3, 0xF2, 0x49, 0xC1, 0xB5,
             0x71, 0xA2, 0x80, 0x28, 0x00, 0x04, 0xE5, 0x7A, 0x3B, 0xCF>>

  @req_bin_fixed <<0x00, 0x01, 0x00, 0x58, 0x21, 0x12, 0xA4, 0x42, 0xB7, 0xE7, 0xA7, 0x01, 0xBC,
                   0x34, 0xD6, 0x86, 0xFA, 0x87, 0xDF, 0xAE, 0x80, 0x22, 0x00, 0x10, 0x53, 0x54,
                   0x55, 0x4E, 0x20, 0x74, 0x65, 0x73, 0x74, 0x20, 0x63, 0x6C, 0x69, 0x65, 0x6E,
                   0x74, 0x00, 0x24, 0x00, 0x04, 0x6E, 0x00, 0x01, 0xFF, 0x80, 0x29, 0x00, 0x08,
                   0x93, 0x2F, 0xF9, 0xB1, 0x51, 0x26, 0x3B, 0x36, 0x00, 0x06, 0x00, 0x09, 0x65,
                   0x76, 0x74, 0x6A, 0x3A, 0x68, 0x36, 0x76, 0x59, 0x00, 0x00, 0x00, 0x00, 0x08,
                   0x00, 0x14, 0x79, 0x07, 0xC2, 0xD2, 0xED, 0xBF, 0xEA, 0x48, 0x0E, 0x4C, 0x76,
                   0xD8, 0x29, 0x62, 0xD5, 0xC3, 0x74, 0x2A, 0xF9, 0xE3, 0x80, 0x28, 0x00, 0x04,
                   0xE3, 0x52, 0x92, 0x8D>>

  @req %Stun{
    class: :request,
    method: :binding,
    transactionid: 56_915_807_328_848_210_473_588_875_182,
    integrity: true,
    key: @password,
    fingerprint: true,
    attrs: %{
      software: <<"STUN test client">>,
      priority: <<110, 0, 1, 255>>,
      ice_controlled: <<147, 47, 249, 177, 81, 38, 59, 54>>,
      username: <<"evtj:h6vY">>
    }
  }

  @resp_ipv4_bin <<0x01, 0x01, 0x00, 0x3C, 0x21, 0x12, 0xA4, 0x42, 0xB7, 0xE7, 0xA7, 0x01, 0xBC,
                   0x34, 0xD6, 0x86, 0xFA, 0x87, 0xDF, 0xAE, 0x80, 0x22, 0x00, 0x0B, 0x74, 0x65,
                   0x73, 0x74, 0x20, 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x20, 0x00, 0x20, 0x00,
                   0x08, 0x00, 0x01, 0xA1, 0x47, 0xE1, 0x12, 0xA6, 0x43, 0x00, 0x08, 0x00, 0x14,
                   0x2B, 0x91, 0xF5, 0x99, 0xFD, 0x9E, 0x90, 0xC3, 0x8C, 0x74, 0x89, 0xF9, 0x2A,
                   0xF9, 0xBA, 0x53, 0xF0, 0x6B, 0xE7, 0xD7, 0x80, 0x28, 0x00, 0x04, 0xC0, 0x7D,
                   0x4C, 0x96>>

  @resp_ipv4_bin_fixed <<0x01, 0x01, 0x00, 0x3C, 0x21, 0x12, 0xA4, 0x42, 0xB7, 0xE7, 0xA7, 0x01,
                         0xBC, 0x34, 0xD6, 0x86, 0xFA, 0x87, 0xDF, 0xAE, 0x80, 0x22, 0x00, 0x0B,
                         0x74, 0x65, 0x73, 0x74, 0x20, 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x00,
                         0x00, 0x20, 0x00, 0x08, 0x00, 0x01, 0xA1, 0x47, 0xE1, 0x12, 0xA6, 0x43,
                         0x00, 0x08, 0x00, 0x14, 0x5D, 0x6B, 0x58, 0xBE, 0xAD, 0x94, 0xE0, 0x7E,
                         0xEF, 0x0D, 0xFC, 0x12, 0x82, 0xA2, 0xBD, 0x08, 0x43, 0x14, 0x10, 0x28,
                         0x80, 0x28, 0x00, 0x04, 0x25, 0x16, 0x7A, 0x15>>

  @resp_ipv4 %Stun{
    class: :success,
    method: :binding,
    transactionid: 56_915_807_328_848_210_473_588_875_182,
    integrity: true,
    key: @password,
    fingerprint: true,
    attrs: %{software: <<"test vector">>, xor_mapped_address: {{192, 0, 2, 1}, 32853}}
  }

  @resp_ipv6_bin <<0x01, 0x01, 0x00, 0x48, 0x21, 0x12, 0xA4, 0x42, 0xB7, 0xE7, 0xA7, 0x01, 0xBC,
                   0x34, 0xD6, 0x86, 0xFA, 0x87, 0xDF, 0xAE, 0x80, 0x22, 0x00, 0x0B, 0x74, 0x65,
                   0x73, 0x74, 0x20, 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x20, 0x00, 0x20, 0x00,
                   0x14, 0x00, 0x02, 0xA1, 0x47, 0x01, 0x13, 0xA9, 0xFA, 0xA5, 0xD3, 0xF1, 0x79,
                   0xBC, 0x25, 0xF4, 0xB5, 0xBE, 0xD2, 0xB9, 0xD9, 0x00, 0x08, 0x00, 0x14, 0xA3,
                   0x82, 0x95, 0x4E, 0x4B, 0xE6, 0x7B, 0xF1, 0x17, 0x84, 0xC9, 0x7C, 0x82, 0x92,
                   0xC2, 0x75, 0xBF, 0xE3, 0xED, 0x41, 0x80, 0x28, 0x00, 0x04, 0xC8, 0xFB, 0x0B,
                   0x4C>>
  @resp_ipv6_bin_fixed <<0x01, 0x01, 0x00, 0x48, 0x21, 0x12, 0xA4, 0x42, 0xB7, 0xE7, 0xA7, 0x01,
                         0xBC, 0x34, 0xD6, 0x86, 0xFA, 0x87, 0xDF, 0xAE, 0x80, 0x22, 0x00, 0x0B,
                         0x74, 0x65, 0x73, 0x74, 0x20, 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x00,
                         0x00, 0x20, 0x00, 0x14, 0x00, 0x02, 0xA1, 0x47, 0x01, 0x13, 0xA9, 0xFA,
                         0xA5, 0xD3, 0xF1, 0x79, 0xBC, 0x25, 0xF4, 0xB5, 0xBE, 0xD2, 0xB9, 0xD9,
                         0x00, 0x08, 0x00, 0x14, 0xBD, 0x03, 0x6D, 0x6A, 0x33, 0x17, 0x50, 0xDF,
                         0xE2, 0xED, 0xC5, 0x8E, 0x64, 0x34, 0x55, 0xCF, 0xF5, 0xC8, 0xE2, 0x64,
                         0x80, 0x28, 0x00, 0x04, 0x4F, 0x26, 0x02, 0x93>>

  @resp_ipv6 %Stun{
    class: :success,
    method: :binding,
    transactionid: 56_915_807_328_848_210_473_588_875_182,
    integrity: true,
    key: @password,
    fingerprint: true,
    attrs: %{
      software: <<"test vector">>,
      xor_mapped_address: {{8193, 3512, 4660, 22136, 17, 8755, 17493, 26231}, 32853}
    }
  }

  # "<U+30DE><U+30C8><U+30EA><U+30C3><U+30AF><U+30B9>"
  @username <<227, 131, 158, 227, 131, 136, 227, 131, 170, 227, 131, 131, 227, 130, 175, 227, 130,
              185>>
  # @password = "The<U+00AD>M<U+00AA>tr<U+2168>",
  @password_after_sasl_prep <<"TheMatrIX">>
  @realm <<"example.org">>
  @nonce <<"f//499k954d6OL34oL9FSTvy64sA">>

  @key :crypto.hash(
         :md5,
         <<@username::binary, ":", @realm::binary, ":", @password_after_sasl_prep::binary>>
       )

  @req_auth_bin <<0x00, 0x01, 0x00, 0x60, 0x21, 0x12, 0xA4, 0x42, 0x78, 0xAD, 0x34, 0x33, 0xC6,
                  0xAD, 0x72, 0xC0, 0x29, 0xDA, 0x41, 0x2E, 0x00, 0x15, 0x00, 0x1C, 0x66, 0x2F,
                  0x2F, 0x34, 0x39, 0x39, 0x6B, 0x39, 0x35, 0x34, 0x64, 0x36, 0x4F, 0x4C, 0x33,
                  0x34, 0x6F, 0x4C, 0x39, 0x46, 0x53, 0x54, 0x76, 0x79, 0x36, 0x34, 0x73, 0x41,
                  0x00, 0x14, 0x00, 0x0B, 0x65, 0x78, 0x61, 0x6D, 0x70, 0x6C, 0x65, 0x2E, 0x6F,
                  0x72, 0x67, 0x00, 0x00, 0x06, 0x00, 0x12, 0xE3, 0x83, 0x9E, 0xE3, 0x83, 0x88,
                  0xE3, 0x83, 0xAA, 0xE3, 0x83, 0x83, 0xE3, 0x82, 0xAF, 0xE3, 0x82, 0xB9, 0x00,
                  0x00, 0x00, 0x08, 0x00, 0x14, 0x3D, 0x64, 0x0E, 0xB8, 0x0B, 0xB3, 0x4B, 0xA0,
                  0x38, 0x54, 0x60, 0x94, 0x1D, 0x3B, 0xCA, 0xC4, 0xF6, 0x90, 0x45, 0x3B>>

  @req_auth %Stun{
    class: :request,
    method: :binding,
    transactionid: 37_347_591_863_512_021_035_078_271_278,
    integrity: true,
    key: @key,
    fingerprint: false,
    attrs: %{
      username: @username,
      nonce: @nonce,
      realm: @realm
    }
  }

  test "Simple decoding of STUN Request" do
    assert {:ok, @req} = Stun.decode(@req_bin, @password)
  end

  test "Simple encoding of STUN Request" do
    assert @req_bin_fixed, Stun.encode(@req)
  end

  test "Simple decoding of STUN IPv4 Response" do
    assert {:ok, @resp_ipv4} = Stun.decode(@resp_ipv4_bin, @password)
  end

  test "Simple encoding of STUN IPv4 Response" do
    assert @resp_ipv4_bin_fixed = Stun.encode(@resp_ipv4)
  end

  test "Simple decoding of STUN IPv6 Response" do
    assert {:ok, @resp_ipv6} = Stun.decode(@resp_ipv6_bin, @password)
  end

  test "Simple encoding of STUN IPv6 Response" do
    assert @resp_ipv6_bin_fixed = Stun.encode(@resp_ipv6)
  end

  test "Simple decoding of STUN Request with auth" do
    assert {:ok, @req_auth} = Stun.decode(@req_auth_bin, @key)
  end

  test "Simple encoding of STUN Request with auth" do
    assert @req_auth_bin = Stun.encode(@req_auth)
  end

  # Server names are taken from Ejabberd's tests
  def public_servers() do
    [
      # address ------- UDP -- TCP -- TLS
      # {'turn01.uswest.xirsys.com', 3478, 3478, 5349},
      # {'stun.fwdnet.net', 3478, 3478, 5349},
      {'stun.ideasip.com', 3478, 3478, 5349}
      # {'stun01.sipphone.com', 3478, 3478, 5349},
      # {'stun.softjoys.com', 3478, 3478, 5349},
      # {'stun.voipbuster.com', 3478, 3478, 5349},
      # {'stun.voxgratia.org', 3478, 3478, 5349},
      # {'stun.xten.com', 3478, 3478, 5349},
      # {'stunserver.org', 3478, 3478, 5349},
      # {'stun.sipgate.net', 10000, 10000, 5349},
      # {'numb.viagenie.ca', 3478, 3478, 5349},
      # {'stun.ipshka.com', 3478, 3478, 5349},
      # {'stun.faktortel.com.au', 3478, 3478, 5349},
      # {'provserver.televolution.net', 3478, 3478, 5349},
      # {'sip1.lakedestiny.cordiaip.com', 3478, 3478, 5349},
      # {'stun1.voiceeclipse.net', 3478, 3478, 5349},
      # {'stun.callwithus.com', 3478, 3478, 5349},
      # {'stun.counterpath.net', 3478, 3478, 5349},
      # {'stun.endigovoip.com', 3478, 3478, 5349},
      # {'stun.internetcalls.com', 3478, 3478, 5349},
      # {'stun.ipns.com', 3478, 3478, 5349},
      # {'stun.noc.ams-ix.net', 3478, 3478, 5349},
      # {'stun.phonepower.com', 3478, 3478, 5349},
      # {'stun.phoneserve.com', 3478, 3478, 5349},
      # {'stun.rnktel.com', 3478, 3478, 5349},
      # {'stun.voxalot.com', 3478, 3478, 5349},
      # {'stun.voip.aebc.com', 3478, 3478, 5349}
    ]
  end

  def mkstun() do
    Stun.encode(%Stun{
      class: :request,
      method: :binding,
      transactionid: :rand.uniform(bsl(1, 96)),
      fingerprint: true,
      attrs: %{software: <<"rtplib v. 0.5.12">>}
    })
  end

  def test_recv(addr, port, :gen_udp) do
    {:ok, sock} = :gen_udp.open(0, [:binary, {:active, false}])
    :gen_udp.send(sock, addr, port, mkstun())

    case :gen_udp.recv(sock, 0, 2000) do
      {:ok, {_, _, data}} ->
        :gen_udp.close(sock)
        {:ok, ret} = Stun.decode(data)
        :error_logger.info_msg("GOT STUN: ~p", [ret])
        ret

      e ->
        e
    end
  end

  def test_recv(addr, port, mod) do
    {:ok, sock} = mod.connect(addr, port, [:binary, {:active, false}], 1000)
    mod.send(sock, mkstun())
    {:ok, data} = mod.recv(sock, 0, 1000)
    mod.close(sock)
    {:ok, ret} = Stun.decode(data)
    :error_logger.info_msg("GOT STUN: ~p", [ret])
    ret
  end

  test "public servers" do
    public_servers()
    |> List.flatten()
    |> Enum.map(fn {addr, udp_p, _tcp_p, _tls_p} ->
      assert(
        %Stun{} = test_recv(addr, udp_p, :gen_udp),
        "Failed to receive STUN resp via UDP from #{inspect(addr)}"
      )
    end)
  end
end
