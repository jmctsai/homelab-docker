# manual mount to linux environment

## Pre-requisite
```
mkdir -p /docker

dpkg -s nfs-common >/dev/null 2>&1 || apt install -y nfs-common
dpkg -s cifs-utils >/dev/null 2>&1 || apt install -y cifs-utils
```

## Mount NFS volume
```
ENTRY="192.168.1.249:/volume1/docker /docker nfs nfsvers=4,rw,noatime,async,hard,intr,_netdev 0 0"

# Check if entry already exists

if ! grep -qF "192.168.1.249:/volume1/docker" /etc/fstab; then
    echo "$ENTRY" | tee -a /etc/fstab
    echo "Added NFS mount to /etc/fstab"
else
    echo "NFS entry already exists in /etc/fstab"
fi
```

## Verify + Reload
```
cat /etc/fstab
mount -a

systemctl daemon-reload
```
