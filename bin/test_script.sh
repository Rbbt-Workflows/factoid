#!/bin/bash

factoid_url='http://factoid.bioinfo.cnio.es/Factoid'
pmid='21960549'

echo "- Processing PMID: $pmid"
echo

docid=`wget "$factoid_url/add_pmid?_format=raw&pmid=$pmid&type=abstract" -O - 2>/dev/null`

echo "- Document ID: $docid"
echo

segments=`wget "$factoid_url/abner?_format=raw&docid=$docid" -O - 2>/dev/null`

echo "- Genes:"
echo
echo "$segments" |  tail -n +3|cut -f 5
echo

echo -n "_format=raw&docid=$docid&segments=" > /tmp/factoid.segments
echo "$segments" >> /tmp/factoid.segments

echo "- Tagged HTML:" 
echo
wget "$factoid_url/tag_segments" --post-file /tmp/factoid.segments -O - 2>/dev/null 
echo
