# OSEP_Scripts
Scripts that might help me for OSEP

## Auto_brute.sh

In order to use it, simply pass all the usernames you got from Domain Controller (`net users /domain`) and pass all the ips present in the forest along with all the possible passwords. You can include NTLM hash also inside the password file, since script will modify its execution if it encounters NTLM hash.
