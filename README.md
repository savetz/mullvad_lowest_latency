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
   
Sample output:

```
# mullvad-exclude ./mullvad_lowest_latency.sh us | head
Avg Latency (ms) | Server Name       | IP Address
-------------------------------------------------
22.13             us-qas-wg-003        198.54.135.98
22.17             us-qas-wg-001        198.54.135.34
22.17             us-qas-wg-102        185.156.46.143
22.17             us-qas-wg-004        198.54.135.130
22.20             us-qas-wg-103        185.156.46.156
22.29             us-qas-wg-101        185.156.46.130
22.36             us-qas-wg-002        198.54.135.66
23.09             us-chi-wg-303        68.235.46.64
```
