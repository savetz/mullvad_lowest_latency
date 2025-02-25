# mullvad lowest latency
shellscript to ping mullvad VPN servers to find ones with lowest latency

1. Runs `mullvad relay list`.
2. Optionally filters by a given country code (e.g. "au").
3. Extracts the first IPv4 address from each line.
4. Pings each server multiple times to get an average latency.
5. Sorts by lowest latency and prints results.

Usage:
   `./mullvad_lowest_latency.sh [COUNTRY_CODE]`
   
Examples:

`./mullvad_lowest_latency.sh         # lists all servers' average latencies`   
`./mullvad_lowest_latency.sh au      # only for Australia`
   
