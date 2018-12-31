defmodule MonitoringHubUtils.SerializationTest do
  use ExUnit.Case

  alias MonitoringHubUtils.Serializers.HubProtocol

  test "computation statistics can be decoded" do
    # This is an actual metrics packet
    packet = <<3,0,0,0,7,109,101,116,114,105,99,115,
      0,0,0,23,109,101,116,114,105,99,115,58,65,108,101,114,
      116,115,95,119,105,110,100,111,119,101,100,
      0,0,2,126,0,0,3,18,0,0,0,25,68,101,99,111,100,101,32,84,105,
      109,101,32,105,110,32,84,67,80,32,83,111,117,114,99,101,
      0,0,0,11,99,111,109,112,117,116,97,116,105,111,110,
      0,0,0,11,105,110,105,116,105,97,108,105,122,101,114,
      0,0,0,17,65,108,101,114,116,115,32,40,119,105,110,100,111,119,101,100,
      41,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,223,218,0,0,
      0,0,0,0,1,249,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,7,0,0,0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,17,0,
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,34,0,0,0,0,0,0,56,173,
      0,0,0,0,119,53,148,0,21,109,192,108,158,34,88,0>>
    {:ok, parsed} = HubProtocol.decode(packet)
    assert parsed == %{
      "event" => "metrics",
      "payload" => %{
        "category" => "computation",
        "id" => "1",
        "latency_list" => [0, 0, 0, 0, 0, 0, 57306, 505, 4,
                           7, 0, 0, 2, 0, 17, 0, 0, 0, 0, 0,
                           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        "max" => 14509,
        "min" => 34,
        "name" => "Alerts (windowed)@initializer:Decode Time in TCP Source",
        "period" => 2,
        "pipeline" => "Alerts (windowed)",
        "timestamp" => 1544101820,
        "worker" => "initializer"
      },
      "ref" => nil,
      "topic" => "metrics:Alerts_windowed"
    }
  end

end
