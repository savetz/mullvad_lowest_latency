#!/usr/bin/env bash
#
# mullvad_lowest_latency.sh
#
# 1. Runs `mullvad relay list`.
# 2. Optionally filters by a given country code (e.g. "au").
# 3. Extracts the first IPv4 address from each line.
# 4. Pings each server multiple times to get an average latency.
# 5. Sorts by lowest latency and prints results.
#
# Usage:
#   ./mullvad_lowest_latency.sh [COUNTRY_CODE]
# Example:
#   ./mullvad_lowest_latency.sh         # lists all servers' average latencies
#   ./mullvad_lowest_latency.sh au      # only for Australia
#

########################################
# User configuration
########################################
PING_COUNT=1  # Number of pings to send. >1 really slows it down
PING_TIMEOUT=2  # Seconds to wait for each ping response

COUNTRY_FILTER="$1"

# Temporary file to store raw data
TMPFILE=$(mktemp)

# Grab mullvad relay list
mullvad relay list > "$TMPFILE" 2>/dev/null

if [ ! -s "$TMPFILE" ]; then
  echo "Error: 'mullvad relay list' returned no data or Mullvad not installed."
  rm -f "$TMPFILE"
  exit 1
fi

# We'll keep track of the current country code while parsing.
current_country=""

# We'll store results in an array "server_name|server_ip"
declare -a SERVERS

# Parse the Mullvad output
while IFS= read -r line; do
  # Check for a line like "Australia (au)"
  if [[ "$line" =~ ^([A-Za-z\ ]+)\ \(([a-z]{2})\) ]]; then
    current_country="${BASH_REMATCH[2]}"    # e.g. "au" or "al"
    continue
  fi

  # If we have a country filter and it doesn't match, skip
  if [[ -n "$COUNTRY_FILTER" && "$COUNTRY_FILTER" != "$current_country" ]]; then
    continue
  fi

  # Look for a line containing server info, e.g.:
  #   au-adl-wg-301 (103.214.20.50, 2404:f780:0:deb::c1f) - WireGuard, ...
  # We'll parse the first IPv4 in parentheses, ignoring IPv6
  if [[ "$line" =~ ^[[:space:]]*([a-z]{2}-[a-z]{3}-[a-z]{2}-[0-9]{3}).*\(([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
    server_name="${BASH_REMATCH[1]}"
    server_ip="${BASH_REMATCH[2]}"
    SERVERS+=( "$server_name|$server_ip" )
  fi
done < "$TMPFILE"

rm -f "$TMPFILE"

if [ "${#SERVERS[@]}" -eq 0 ]; then
  echo "No servers found (maybe invalid country code?)."
  exit 0
fi

# We'll store them in an array "latency|server_name|server_ip"
declare -a RESULTS

for entry in "${SERVERS[@]}"; do
  server_name="${entry%%|*}"
  server_ip="${entry##*|}"

  # Ping multiple times
  ping_output=$(ping -c "$PING_COUNT" -W "$PING_TIMEOUT" "$server_ip" 2>/dev/null)
  if [ $? -eq 0 ]; then
    # Look for a line like: "rtt min/avg/max/mdev = 21.243/22.788/25.607/1.593 ms"
    # We'll extract the 'avg' portion, i.e. second field after splitting on '/'
    avg=$(echo "$ping_output" | awk -F'/' '/min\/avg\/max/ {print $5}')
    if [[ -n "$avg" ]]; then
      latency="$avg"
    else
      # If somehow we fail to parse, set to high latency
      latency="9999"
    fi
  else
    # Timed out or no reply
    latency="9999"
  fi
  RESULTS+=( "$latency|$server_name|$server_ip" )
done

# Sort by latency numerically
IFS=$'\n' RESULTS_SORTED=($(sort -t'|' -k1n <<< "${RESULTS[*]}"))
unset IFS

# Print the results in ascending order of average latency
echo "Avg Latency (ms) | Server Name       | IP Address"
echo "-------------------------------------------------"
for line in "${RESULTS_SORTED[@]}"; do
  latency="${line%%|*}"
  rest="${line#*|}"
  server_name="${rest%%|*}"
  server_ip="${rest##*|}"
  # Format latency to 2 decimals
  latency_fmt=$(printf "%.2f" "$latency")
  printf "%-15s   %-18s   %s\n" "$latency_fmt" "$server_name" "$server_ip"
done
