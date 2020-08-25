#!/bin/bash

set -e
set -vx
export LC_ALL=C
export FILE_HOST="${FILE_HOST:-cloud-images.ubuntu.com}"
#OSID="${OSID:-ubuntu}"
TARGET="${TARGET:-amd64}"
BRANCH="${BRANCH:-daily}"
CODENAME="${CODENAME:-bionic}"

gpg_fingerprint="${gpg_fingerprint:-
9DC858229FC7DD38854AE2D88D81803C0EBFCD88
4A3CE3CD565D7EB5C810E2B97FF3F408476CF100
}"
key_servers="${key_servers:-
keyserver.ubuntu.com
ha.pool.sks-keyservers.net
pgp.mit.edu
}"

cd $WORKDIR

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

curl=''
if command_exists curl; then
	#curl='curl -sSL'
	curl='$(command -v curl)'
	#curlopt="--silent --show-error --fail --progress-bar -L --max-redirs 3 --retry 3 --retry-delay 2 --max-time 30"
	#curlopt="-C- --show-error --fail --progress-bar -L --max-redirs 3 --retry 3 --retry-delay 2 --max-time 30"
	curlopt="--show-error --fail --progress-bar -L --max-redirs 3 --retry 3 --retry-delay 2 --max-time 30"
elif command_exists wget && wget --version | grep -q GNU; then
	#curl='wget -qO-'
	curl='$(command -v wget)'
	curlopt='--tries=3 --retry-connrefused --continue --progress=dot:giga --server-response'
elif command_exists busybox && busybox --list-modules | grep -q wget; then
	#curl='busybox wget -qO-'
	curl='$(command -v busybox wget)'
	curlopt='-qO-'
fi

gpg=''
#gpgdefaultopt='--debug-all --fingerprint --fingerprint --batch --keyid-format=long --with-fingerprint'
gpgdefaultopt='--verbose --status-fd 1 --fingerprint --batch --keyid-format=long --with-fingerprint'
if command_exists gpg1; then
        #curl='curl -sSL'
        gpg=$(command -v gpg1)
	gpgopt="$gpgdefaultopt"
	gpgver='1'
elif command_exists gpg2; then
        #curl='wget -qO-'
        gpg=$(command -v gpg2)
	gpgopt="$gpgdefaultopt"
	gpgver='2'
elif command_exists gpg && gpg --batch --version | grep -q "gpg (GnuPG) 1."; then
	gpg=$(command -v gpg)
	gpgopt="$gpgdefaultopt"
	gpgver='1'
elif command_exists gpg && gpg --batch --version | grep -q "gpg (GnuPG) 2."; then
	gpg=$(command -v gpg)
	gpgopt="$gpgdefaultopt"
	gpgver='2'
fi

(
set -x
for key_server in $key_servers ; do
       $gpg $gpgopt --keyserver hkp://${key_server}:80 --recv-keys ${gpg_fingerprint} && break
done
)

(
set -x
for keys in $gpg_fingerprint ; do
       echo "${keys}:6:" | $gpg $gpgopt --import-ownertrust -
done
)


#http://cloud-images.ubuntu.com/minimal/daily/xenial/current/xenial-minimal-cloudimg-amd64-disk1.img
#http://cloud-images.ubuntu.com/minimal/daily/focal/current/focal-minimal-cloudimg-amd64.img
#http://cloud-images.ubuntu.com/minimal/daily/bionic/current/bionic-minimal-cloudimg-amd64.img
#http://cloud-images.ubuntu.com/minimal/daily/groovy/current/groovy-minimal-cloudimg-amd64.img
#http://cloud-images.ubuntu.com/minimal/daily/xenial/current/xenial-minimal-cloudimg-amd64-disk1.img
#http://cloud-images.ubuntu.com/minimal/daily/xenial/current/xenial-minimal-cloudimg-amd64-uefi1.img


#http://cloud-images.ubuntu.com/minimal/releases/bionic/release-20200806/ubuntu-18.04-minimal-cloudimg-amd64.img
#http://cloud-images.ubuntu.com/minimal/releases/bionic/release/ubuntu-18.04-minimal-cloudimg-amd64.img

#http://cloud-images.ubuntu.com/minimal/releases/focal/release-20200729/ubuntu-20.04-minimal-cloudimg-amd64.img
#http://cloud-images.ubuntu.com/minimal/releases/focal/release/ubuntu-20.04-minimal-cloudimg-amd64.img

#http://cloud-images.ubuntu.com/minimal/releases/xenial/release-20200814/ubuntu-16.04-minimal-cloudimg-amd64-disk1.img
#http://cloud-images.ubuntu.com/minimal/releases/xenial/release/ubuntu-16.04-minimal-cloudimg-amd64-disk1.img

if [ "$BRANCH" == "daily" ]; then
    #export DOWNLOAD_PATH="snapshots/targets/$(echo $TARGET | tr '-' '/')"
    #export DOWNLOAD_FILE="${DOWNLOAD_FILE:-*generic-squashfs-combined.img.gz}"
    export DOWNLOAD_PATH="minimal/daily/$CODENAME/current"
    export DOWNLOAD_FILE="${DOWNLOAD_FILE:-$CODENAME-minimal-cloudimg-$TARGET.img}"
    export DOWNLOAD_FILE_HASHFILE="${DOWNLOAD_FILE_HASHFILE:-SHA256SUMS}"
    export HASH_CMD="sha256sum -c"

else
    #export DOWNLOAD_PATH="releases/$BRANCH/targets/$(echo $TARGET | tr '-' '/')"
    #export DOWNLOAD_FILE="${DOWNLOAD_FILE:-*combined-squashfs.img.gz}"
    export DOWNLOAD_PATH="minimal/releases/$CODENAME/$BRANCH"
    export DOWNLOAD_FILE="${DOWNLOAD_FILE:-$CODENAME-minimal-cloudimg-$TARGET.img}"
    export DOWNLOAD_FILE_HASHFILE="${DOWNLOAD_FILE_HASHFILE:-SHA256SUMS}"
    export HASH_CMD="sha256sum -c"
fi

#curlopt="--progress-bar --show-error -L --max-redirs 3 --retry 3 --retry-connrefused --retry-delay 2 --max-time 30"
###curlopt="--progress-bar --show-error -L --max-redirs 3 --retry 3 --retry-delay 2 --max-time 30"
curl $curlopt "https://$FILE_HOST/$DOWNLOAD_PATH/$DOWNLOAD_FILE_HASHFILE" -o $DOWNLOAD_FILE_HASHFILE
curl $curlopt "https://$FILE_HOST/$DOWNLOAD_PATH/$DOWNLOAD_FILE_HASHFILE.asc" -o $DOWNLOAD_FILE_HASHFILE.asc || true
curl $curlopt "https://$FILE_HOST/$DOWNLOAD_PATH/$DOWNLOAD_FILE_HASHFILE.sig" -o $DOWNLOAD_FILE_HASHFILE.sig || true
curl $curlopt "https://$FILE_HOST/$DOWNLOAD_PATH/$DOWNLOAD_FILE_HASHFILE.gpg" -o $DOWNLOAD_FILE_HASHFILE.gpg || true
if [ ! -f $DOWNLOAD_FILE_HASHFILE.asc ]  && [ ! -f $DOWNLOAD_FILE_HASHFILE.sig ] && [ ! -f $DOWNLOAD_FILE_HASHFILE.gpg ]; then
    echo "Missing $DOWNLOAD_FILE_HASHFILE signature files"
    exit 1
fi
#[ ! -f $DOWNLOAD_FILE_HASHFILE.asc ] || $($gpg $gpgopt --list-packets $DOWNLOAD_FILE_HASHFILE.asc; $gpg $gpgopt --verify $DOWNLOAD_FILE_HASHFILE.asc $DOWNLOAD_FILE_HASHFILE; )

#[ ! -f $DOWNLOAD_FILE_HASHFILE.gpg ] || $($gpg $gpgopt --list-packets $DOWNLOAD_FILE_HASHFILE.gpg; $gpg $gpgopt --verify $DOWNLOAD_FILE_HASHFILE.gpg $DOWNLOAD_FILE_HASHFILE; )

[ ! -f $DOWNLOAD_FILE_HASHFILE.asc ] || $gpg $gpgopt --verify $DOWNLOAD_FILE_HASHFILE.asc $DOWNLOAD_FILE_HASHFILE

[ ! -f $DOWNLOAD_FILE_HASHFILE.gpg ] || $gpg $gpgopt --verify $DOWNLOAD_FILE_HASHFILE.gpg $DOWNLOAD_FILE_HASHFILE

if [ -f $DOWNLOAD_FILE_HASHFILE.sig ]; then
	if hash signify-openbsd 2>/dev/null; then
		SIGNIFY_BIN=signify-openbsd # debian
	else
		SIGNIFY_BIN=signify # alpine
	fi
    VERIFIED=
    for KEY in ./usign/*; do
        echo "Trying $KEY..."
        if "$SIGNIFY_BIN" -V -q -p "$KEY" -x $DOWNLOAD_FILE_HASHFILE.sig -m $DOWNLOAD_FILE_HASHFILE; then
            echo "...verified"
            VERIFIED=1
            break
        fi
    done
    if [ -z "$VERIFIED" ]; then
        echo "Could not verify usign signature"
        exit 1
    fi
fi

# shrink checksum file to single desired file and verify downloaded archive
set -vx
###rsync -av "$FILE_HOST::downloads/$DOWNLOAD_PATH/$DOWNLOAD_FILE" . || exit 1
#url_effective=$(curl -Ls --write-out %{url_effective} -o /dev/null http://$FILE_HOST/$DOWNLOAD_PATH/$DOWNLOAD_FILE)
#curl $curlopt -C- $url_effective -o $DOWNLOAD_FILE
grep $DOWNLOAD_FILE $DOWNLOAD_FILE_HASHFILE > $DOWNLOAD_FILE_HASHFILE\_min
$HASH_CMD $DOWNLOAD_FILE_HASHFILE\_min || curl $curlopt "http://$FILE_HOST/$DOWNLOAD_PATH/$DOWNLOAD_FILE" -o $DOWNLOAD_FILE
#set +vx
#grep $DOWNLOAD_FILE $DOWNLOAD_FILE_HASHFILE > $DOWNLOAD_FILE_HASHFILE\_min
$HASH_CMD $DOWNLOAD_FILE_HASHFILE\_min
###rm -f $DOWNLOAD_FILE_HASHFILE{,_min,.sig,.asc}

BOOT_FILE="$(ls $DOWNLOAD_FILE)"
if [ ! -f "$BOOT_FILE" -a -s "$BOOT_FILE.gz" ]; then
    gunzip "$BOOT_FILE.gz"
    BOOT_FILE="$(basename $BOOT_FILE .gz)"
fi

QEMU_HDA="${QEMU_HDA:-$DOWNLOAD_FILE.hda}"
cp -p $DOWNLOAD_FILE $QEMU_HDA
QEMU_CPU="${QEMU_CPU:-1}"
QEMU_RAM="${QEMU_RAM:-512}"
QEMU_CDROM="${QEMU_CDROM:-my-user-data.img}"
QEMU_BOOT="${QEMU_BOOT:-c}"

# main available options:
#   QEMU_CPU=n    (cores)
#   QEMU_RAM=nnn  (megabytes)
#   QEMU_HDA      (filename)
#   QEMU_HDA_SIZE (bytes, suffixes like "G" allowed)
#   QEMU_CDROM    (filename)
#   QEMU_BOOT     (-boot)
#   QEMU_PORTS="xxx[ xxx ...]" (space separated port numbers)
#   QEMU_NET_USER_EXTRA="net=192.168.76.0/24,dhcpstart=192.168.76.9" (extra raw args for "-net user,...")
#   QEMU_NO_SSH=1 (suppress automatic port 22 forwarding)
#   QEMU_NO_SERIAL=1 (suppress automatic "-serial stdio")

hostArch="$(uname -m)"
qemuArch="${QEMU_ARCH:-$hostArch}"
qemu="${QEMU_BIN:-qemu-system-$qemuArch}"
qemuArgs=()

qemuPorts=()
if [ -z "${QEMU_NO_SSH:-}" ]; then
	qemuPorts+=( 22 )
fi
qemuPorts+=( ${QEMU_PORTS:-} )

if [ -e /dev/kvm ]; then
	qemuArgs+=( -enable-kvm )
elif [ "$hostArch" = "$qemuArch" ]; then
	echo >&2
	echo >&2 'warning: /dev/kvm not found'
	echo >&2 '  PERFORMANCE WILL SUFFER'
	echo >&2 '  (hint: docker run --device /dev/kvm ...)'
	echo >&2
	sleep 3
fi

qemuArgs+=( -smp "${QEMU_CPU:-1}" )
qemuArgs+=( -m "${QEMU_RAM:-512}" )

if [ -n "${QEMU_HDA:-}" ]; then
	if [ ! -f "$QEMU_HDA" -o ! -s "$QEMU_HDA" ]; then
		(
			set -x
			qemu-img create -f qcow2 -o preallocation=off "$QEMU_HDA" "${QEMU_HDA_SIZE:-8G}"
		)
	fi

	# http://wiki.qemu.org/download/qemu-doc.html#Invocation
	qemuScsiDevice='virtio-scsi-pci'
	case "$qemuArch" in
		arm) qemuScsiDevice='virtio-scsi-device' ;;
	esac

	#qemuArgs+=( -hda "$QEMU_HDA" )
	#qemuArgs+=( -drive file="$QEMU_HDA",index=0,media=disk,discard=unmap )
	qemuArgs+=(
		-drive file="$QEMU_HDA",index=0,media=disk,discard=unmap,detect-zeroes=unmap,if=none,id=hda
		-device "$qemuScsiDevice"
		-device scsi-hd,drive=hda
	)
fi

if [ -e my-user-data ]; then
        #cloud-localds my-seed.img my-user-data
	#cloud-localds --disk-format qcow2 --dsmode local my-seed.img my-user-data
	cloud-localds --disk-format qcow2 --dsmode local my-user-data.img my-user-data
elif [ ! -e my-user-data.img ]; then
cat > my-user-data <<EOF
#cloud-config
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant-insecure-public-key 
  - ssh-ed25519 AA...................U1 ed25519-key-dummy
# see also https://github.com/hashicorp/vagrant/tree/master/keys
password: passw0rd
chpasswd: { expire: False }
ssh_pwauth: True
# 
EOF
	echo >&2
        echo >&2 'warning: my-user-data / my-user-data.img found'
        echo >&2 '  create file with:'
	echo >&2 'cat my-user-data'
	cat my-user-data >&2
        echo >&2
        sleep 10

fi

# see https://github.com/hashicorp/vagrant/tree/master/keys
cat > vagrant.pub <<EOF2
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant-insecure-public-key
EOF2

cat > vagrant.id <<EOF3
-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzI
w+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoP
kcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2
hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NO
Td0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcW
yLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQIBIwKCAQEA4iqWPJXtzZA68mKd
ELs4jJsdyky+ewdZeNds5tjcnHU5zUYE25K+ffJED9qUWICcLZDc81TGWjHyAqD1
Bw7XpgUwFgeUJwUlzQurAv+/ySnxiwuaGJfhFM1CaQHzfXphgVml+fZUvnJUTvzf
TK2Lg6EdbUE9TarUlBf/xPfuEhMSlIE5keb/Zz3/LUlRg8yDqz5w+QWVJ4utnKnK
iqwZN0mwpwU7YSyJhlT4YV1F3n4YjLswM5wJs2oqm0jssQu/BT0tyEXNDYBLEF4A
sClaWuSJ2kjq7KhrrYXzagqhnSei9ODYFShJu8UWVec3Ihb5ZXlzO6vdNQ1J9Xsf
4m+2ywKBgQD6qFxx/Rv9CNN96l/4rb14HKirC2o/orApiHmHDsURs5rUKDx0f9iP
cXN7S1uePXuJRK/5hsubaOCx3Owd2u9gD6Oq0CsMkE4CUSiJcYrMANtx54cGH7Rk
EjFZxK8xAv1ldELEyxrFqkbE4BKd8QOt414qjvTGyAK+OLD3M2QdCQKBgQDtx8pN
CAxR7yhHbIWT1AH66+XWN8bXq7l3RO/ukeaci98JfkbkxURZhtxV/HHuvUhnPLdX
3TwygPBYZFNo4pzVEhzWoTtnEtrFueKxyc3+LjZpuo+mBlQ6ORtfgkr9gBVphXZG
YEzkCD3lVdl8L4cw9BVpKrJCs1c5taGjDgdInQKBgHm/fVvv96bJxc9x1tffXAcj
3OVdUN0UgXNCSaf/3A/phbeBQe9xS+3mpc4r6qvx+iy69mNBeNZ0xOitIjpjBo2+
dBEjSBwLk5q5tJqHmy/jKMJL4n9ROlx93XS+njxgibTvU6Fp9w+NOFD/HvxB3Tcz
6+jJF85D5BNAG3DBMKBjAoGBAOAxZvgsKN+JuENXsST7F89Tck2iTcQIT8g5rwWC
P9Vt74yboe2kDT531w8+egz7nAmRBKNM751U/95P9t88EDacDI/Z2OwnuFQHCPDF
llYOUI+SpLJ6/vURRbHSnnn8a/XG+nzedGH5JGqEJNQsz+xT2axM0/W/CRknmGaJ
kda/AoGANWrLCz708y7VYgAtW2Uf1DPOIYMdvo6fxIB5i9ZfISgcJ/bbCUkFrhoH
+vq/5CIWxCPp0f85R4qxxQ5ihxJ0YDQT9Jpx4TMss4PSavPaBH3RXow5Ohe+bYoQ
NE5OgEXk2wVfZczCZpigBKbKZHNYcelXtTt/nP3rsCuGcM4h53s=
-----END RSA PRIVATE KEY-----
EOF3

if [ -n "${QEMU_CDROM:-}" ]; then
	qemuArgs+=( -cdrom "$QEMU_CDROM" )
fi

if [ -n "${QEMU_BOOT:-}" ]; then
	qemuArgs+=( -boot "$QEMU_BOOT" )
fi

netArg='user'
netArg+=",hostname=$(hostname)"
if [ -n "${QEMU_NET_USER_EXTRA:-}" ]; then
	netArg+=",$QEMU_NET_USER_EXTRA"
fi
for port in "${qemuPorts[@]}"; do
	netArg+=",hostfwd=tcp::$port-:$port"
	netArg+=",hostfwd=udp::$port-:$port"
done

qemuNetDevice='virtio-net-pci'
case "$qemuArch" in
	arm) qemuNetDevice='virtio-net-device' ;;
esac

qemuArgs+=(
	-netdev "$netArg,id=net"
	-device "$qemuNetDevice,netdev=net"
	-vnc ':0'
)
if [ -z "${QEMU_NO_SERIAL:-}" ]; then
	qemuArgs+=(
		-serial stdio
	)
fi
#qemuArgs+=( "$@" )
set 
set -vx
exec "$qemu" -version
exec "$qemu" -accel help
exec "$qemu" "${qemuArgs[@]}"
#exec "$qemu" "${qemuArgs[@]}"
echo "#############################"
