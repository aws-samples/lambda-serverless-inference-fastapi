#!/usr/bin/env bash -e 

req_files="$(find . -name requirements\*.txt)"
echo $req_files

python -m venv notice_licenses && . .venv/bin/activate
pip install pip-licenses==4.0.1

for f in $req_files
do    
    pip install -r ${f}
done
rm NOTICE || true
pip-licenses --output NOTICE
rm -r notice_licenses || true
