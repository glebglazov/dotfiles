function jj-forget-old-bookmarks() {
    jj bookmark list --all-remotes | \
        awk '{print $1}' | \
        sed 's/.$//' | \
        grep -v '^@' | \
        while read bookmark; do
            if [ ! -z "$bookmark" ]; then
                # Get the commit date for this bookmark
                commit_date=$(jj log -r "$bookmark" --no-graph -T 'self.committer().timestamp()' | head -1)

                if [ ! -z "$commit_date" ]; then
                    # Strip milliseconds and fix timezone format
                    # "2025-11-28 12:19:03.000 +01:00" -> "2025-11-28 12:19:03 +0100"
                    commit_date_fixed=$(echo "$commit_date" | sed 's/\.[0-9]* / /' | sed 's/\([+-][0-9][0-9]\):\([0-9][0-9]\)/\1\2/')
                    # Convert commit date to timestamp
                    commit_timestamp=$(date -j -f "%Y-%m-%d %H:%M:%S %z" "$commit_date_fixed" "+%s" 2>/dev/null || echo "0")

                    # Calculate timestamp for 3 months ago
                    three_months_ago=$(date -v-3m "+%s")

                    # Check if bookmark is older than 3 months
                    if [ "$commit_timestamp" -lt "$three_months_ago" ] && [ "$commit_timestamp" != "0" ]; then
                        echo "Forgetting old bookmark: $bookmark (commit date: $commit_date)"
                        jj bookmark forget "$bookmark"
                    fi
                fi
            fi
        done
}
