#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ

umask 022
/sbin/ldconfig

#apt install -y bash wget ca-certificates curl
#apt install -y binutils coreutils util-linux findutils diffutils patch sed gawk grep file gzip bzip2 xz-utils tar

#https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-4.4.12.tgz
#https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-5.0.6.tgz
#https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel80-4.4.12.tgz
#https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel80-5.0.6.tgz

#https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1804-4.4.12.tgz
#https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1804-5.0.6.tgz
#https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu2004-4.4.12.tgz
#https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu2004-5.0.6.tgz

#https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1604-4.4.12.tgz

#https://fastdl.mongodb.org/tools/db/mongodb-database-tools-rhel70-x86_64-100.5.2.tgz
#https://fastdl.mongodb.org/tools/db/mongodb-database-tools-rhel80-x86_64-100.5.2.tgz
#https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu1604-x86_64-100.5.2.tgz
#https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2004-x86_64-100.5.2.tgz

# _mongodb_distro
# < rhel70 | rhel80 | ubuntu2004 | ubuntu1804 | ubuntu1604 >

# _mongodb_ver
# < 5.0 | 4.4 >

set -e

cd "$(dirname "$0")"

_dl_mongodb() {
    set -e
    _old_dir="$(pwd)"
    _tmp_dir="$(mktemp -d)"
    cd "${_tmp_dir}"
    _mongodb_distro="${1}"
    _mongodb_ver="${2}"
    _mongodb_database_tools_ver="$(wget -qO- 'https://www.mongodb.com/try/download/database-tools' | sed 's|"|\n|g' | grep -i "^https.*mongodb-database-tools-${_mongodb_distro}.*x86_64.*\.tgz" | sed -e 's|.*x86_64-||g' -e 's|\.t.*||g' | sort -V | uniq | tail -n 1)"
    _mongodb_ver="$(wget -qO- 'https://www.mongodb.com/try/download/community' | sed 's|"|\n|g' | grep -i 'https' | grep -i "mongodb-linux-x86_64-${_mongodb_distro}.*-${_mongodb_ver}.*\.tgz" | sed -e 's|.*-||g' -e 's|\.t.*||g' | grep -ivE 'alpha|beta|rc' |sort -V | uniq | tail -n 1)"
    _mongodb_distro="$(wget -qO- 'https://www.mongodb.com/try/download/community' | sed 's|"|\n|g' | grep -i 'https' | grep -i "mongodb-linux-x86_64-${_mongodb_distro}.*-${_mongodb_ver}.*\.tgz" | grep -ivE 'alpha|beta|rc' | sed -e "s|.*mongodb-linux-x86_64-||g" -e "s|-${_mongodb_ver}.*||g" | sort -V | uniq | tail -n 1)"
    wget -q -c -t 9 -T 9 "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${_mongodb_distro}-${_mongodb_ver}.tgz"
    wget -q -c -t 9 -T 9 "https://fastdl.mongodb.org/tools/db/mongodb-database-tools-${_mongodb_distro}-x86_64-${_mongodb_database_tools_ver}.tgz"
    _mongosh_ver="$(wget -qO- 'https://www.mongodb.com/try/download/database-tools' | sed 's|"|\n|g' | grep -i '^https.*mongosh-.*-linux-x64.t' | sed -e 's|.*mongosh-||g' -e 's|-linux.*||g' | sort -V | uniq | tail -n 1)"
    wget -q -c -t 9 -T 9 "https://downloads.mongodb.com/compass/mongosh-${_mongosh_ver}-linux-x64.tgz"
    echo
    /bin/ls -lah --color ./
    echo
    tar -xf "mongodb-linux-x86_64-${_mongodb_distro}-${_mongodb_ver}.tgz"
    tar -xf "mongodb-database-tools-${_mongodb_distro}-x86_64-${_mongodb_database_tools_ver}.tgz"
    tar -xf "mongosh-${_mongosh_ver}-linux-x64.tgz"
    sleep 1
    rm -f *.tgz
    rm -fr /tmp/mongodb
    sleep 1
    install -m 0755 -d /tmp/mongodb/usr
    install -m 0755 -d /tmp/mongodb/etc/mongodb
    cp -a "mongodb-linux-x86_64-${_mongodb_distro}-${_mongodb_ver}/bin" /tmp/mongodb/usr/
    cp -a "mongodb-database-tools-${_mongodb_distro}-x86_64-${_mongodb_database_tools_ver}/bin"/* /tmp/mongodb/usr/bin/
    cp -a "mongosh-${_mongosh_ver}-linux-x64/bin"/* /tmp/mongodb/usr/bin/

    cd /tmp/mongodb
    chmod 0755 usr/bin/*
    sleep 1
    find usr/bin/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'
    sleep 1
    [ -f usr/bin/mongocryptd-mongosh ] && ( install -m 0755 -d usr/libexec ; \
        mv -f usr/bin/mongocryptd-mongosh usr/libexec/ )
    
    install -m 0644 "${_old_dir}"/mongod.conf.default etc/mongodb/
    install -m 0644 "${_old_dir}"/mongod.service etc/mongodb/
    install -m 0644 "${_old_dir}"/.install.txt etc/mongodb/

    sleep 1
    chown -R root:root /tmp/mongodb
    echo
    sleep 2
    #tar -Jcvf /tmp/"mongodb-${_mongodb_ver}-x86_64-${_mongodb_distro}.tar.xz" *
    tar --format=gnu -cf - * | xz --threads=2 -f -z -9 > /tmp/"mongodb-${_mongodb_ver}-x86_64-${_mongodb_distro}.tar.xz"
    echo
    sleep 2
    cd /tmp
    sha256sum "mongodb-${_mongodb_ver}-x86_64-${_mongodb_distro}.tar.xz" > "mongodb-${_mongodb_ver}-x86_64-${_mongodb_distro}.tar.xz".sha256

    cd /tmp
    sleep 2
    rm -fr "${_tmp_dir}"
    rm -fr /tmp/mongodb
    echo
    printf '\e[01;32m%s\e[m\n' " package mongodb ${_mongodb_ver} ${_mongodb_distro} done"
    echo
    cd "${_old_dir}"
}

if [[ "${1}" == 'all' ]] || [[ "${1}" == 'All' ]]; then
    _dl_mongodb rhel7 5.0
    _dl_mongodb rhel8 5.0
    _dl_mongodb ubuntu2004 5.0
    _dl_mongodb ubuntu1804 5.0

    _dl_mongodb rhel7 4.4
    _dl_mongodb rhel8 4.4
    _dl_mongodb ubuntu2004 4.4
    _dl_mongodb ubuntu1804 4.4

    _dl_mongodb ubuntu1604 4.4
    exit
fi

if [[ -z "${1}" ]] || [[ -z "${2}" ]]; then
    echo
    echo "bash $0 < rhel7 | rhel8 | ubuntu2004 | ubuntu1804 >  < 5.0 | 4.4 >"
    echo "bash $0 ubuntu1604  4.4"
    echo "bash $0 all"
    echo
else
    _dl_mongodb "${1}" "${2}"
fi

exit

