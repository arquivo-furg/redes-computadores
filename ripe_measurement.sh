curl -H "Authorization: Key RIPE_ATLAS_KEY" \
     -H "Content-Type: application/json" \
     -X POST \
     -d '{
  "definitions": [
    {
      "type": "traceroute", "af": 4, "resolve_on_probe": true,
      "description": "Traceroute measurement to music.youtube.com",
      "response_timeout": 4000, "protocol": "ICMP", "packets": 3,
      "size": 48, "first_hop": 1, "max_hops": 32, "paris": 16,
      "destination_option_size": 0, "hop_by_hop_option_size": 0,
      "dont_fragment": false, "skip_dns_check": false,
      "target": "music.youtube.com", "interval": 3600,
      "auto_topup": false, "auto_topup_prb_days_off": 7, "auto_topup_prb_similarity": 0.5
    },
    {
      "type": "traceroute", "af": 6, "resolve_on_probe": true,
      "description": "Traceroute measurement to music.youtube.com",
      "response_timeout": 4000, "protocol": "ICMP", "packets": 3,
      "size": 48, "first_hop": 1, "max_hops": 32, "paris": 16,
      "destination_option_size": 0, "hop_by_hop_option_size": 0,
      "dont_fragment": false, "skip_dns_check": false,
      "target": "music.youtube.com", "interval": 3600,
      "auto_topup": false, "auto_topup_prb_days_off": 7, "auto_topup_prb_similarity": 0.5
    },
    {
      "type": "traceroute", "af": 4, "resolve_on_probe": true,
      "description": "Traceroute measurement to music.apple.com",
      "response_timeout": 4000, "protocol": "ICMP", "packets": 3,
      "size": 48, "first_hop": 1, "max_hops": 32, "paris": 16,
      "destination_option_size": 0, "hop_by_hop_option_size": 0,
      "dont_fragment": false, "skip_dns_check": false,
      "target": "music.apple.com", "interval": 3600,
      "auto_topup": false, "auto_topup_prb_days_off": 7, "auto_topup_prb_similarity": 0.5
    },
    {
      "type": "traceroute", "af": 6, "resolve_on_probe": true,
      "description": "Traceroute measurement to music.apple.com",
      "response_timeout": 4000, "protocol": "ICMP", "packets": 3,
      "size": 48, "first_hop": 1, "max_hops": 32, "paris": 16,
      "destination_option_size": 0, "hop_by_hop_option_size": 0,
      "dont_fragment": false, "skip_dns_check": false,
      "target": "music.apple.com", "interval": 3600,
      "auto_topup": false, "auto_topup_prb_days_off": 7, "auto_topup_prb_similarity": 0.5
    },
    {
      "type": "traceroute", "af": 4, "resolve_on_probe": true,
      "description": "Traceroute measurement to open.spotify.com",
      "response_timeout": 4000, "protocol": "ICMP", "packets": 3,
      "size": 48, "first_hop": 1, "max_hops": 32, "paris": 16,
      "destination_option_size": 0, "hop_by_hop_option_size": 0,
      "dont_fragment": false, "skip_dns_check": false,
      "target": "open.spotify.com", "interval": 3600,
      "auto_topup": false, "auto_topup_prb_days_off": 7, "auto_topup_prb_similarity": 0.5
    },
    {
      "type": "traceroute", "af": 6, "resolve_on_probe": true,
      "description": "Traceroute measurement to open.spotify.com",
      "response_timeout": 4000, "protocol": "ICMP", "packets": 3,
      "size": 48, "first_hop": 1, "max_hops": 32, "paris": 16,
      "destination_option_size": 0, "hop_by_hop_option_size": 0,
      "dont_fragment": false, "skip_dns_check": false,
      "target": "open.spotify.com", "interval": 3600,
      "auto_topup": false, "auto_topup_prb_days_off": 7, "auto_topup_prb_similarity": 0.5
    }
  ],
  "probes": [
    {"type": "country", "value": "BR", "requested": 3},
    {"type": "country", "value": "MX", "requested": 3},
    {"type": "country", "value": "US", "requested": 3},
    {"type": "country", "value": "JP", "requested": 3},
    {"type": "country", "value": "IN", "requested": 3},
    {"type": "country", "value": "SG", "requested": 3},
    {"type": "country", "value": "DE", "requested": 3},
    {"type": "country", "value": "FR", "requested": 3},
    {"type": "country", "value": "FI", "requested": 3},
    {"type": "country", "value": "NG", "requested": 3},
    {"type": "country", "value": "ZA", "requested": 3},
    {"type": "country", "value": "KE", "requested": 3},
    {"type": "country", "value": "AU", "requested": 3},
    {"type": "country", "value": "NZ", "requested": 3},
    {"type": "country", "value": "NC", "requested": 3}
  ],
  "is_oneoff": false,
  "bill_to": "pedro.machado@furg.br",
  "start_time": "2026-06-29T11:30:00Z",
  "stop_time": "2026-06-30T11:30:00Z"
}' \
https://atlas.ripe.net/api/v2/measurements/
