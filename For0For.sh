#!/bin/bash

if [ -n "$1" ]; then
    TARGET="$1"
else
    TARGET=$(curl -s https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/main/data/wildcards.txt | shuf -n 1 | sed 's/ /%20/g')
fi

echo "Selected target: $TARGET"

> files.txt
> ext-counts.txt

if [[ ! "$TARGET" =~ ^https?:// ]]; then
    TARGET="https://$TARGET"
fi

TARGET_DOMAIN=$(echo "$TARGET" | awk -F[/:] '{print $4}')

curl -s "https://web.archive.org/cdx/search/cdx?url=${TARGET}/*&collapse=urlkey&output=text&fl=original&filter=original:.*\.(sql|db|backup|bak|yml|yaml|ini|csv|conf|config|cfg|crt|pem|key|asc|env|git|svn)$" | \
while read -r file; do
    if [ ! -z "$file" ]; then
        echo "$file" >> files.txt
    fi
done

if [ -s files.txt ]; then
    awk -F. '{print $NF}' files.txt | sort | uniq -c | sort -rn > ext-counts.txt
    
    FILE_COUNT=$(cat files.txt | wc -l)
    EXTENSION_COUNTS=$(awk '{printf "%s: %s\n", $2, $1}' ext-counts.txt)
    
    cat << EOF
{
    "content": "Target: $TARGET_DOMAIN\\n\\nFound $FILE_COUNT sensitive files!\\n\\nFound exts:\\n$EXTENSION_COUNTS\\n\\n🔗 First 5 files found:\\n$(head -n 5 files.txt | sed 's/^/- /')"
}
EOF
fi
