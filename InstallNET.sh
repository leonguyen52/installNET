#!/bin/bash

## It can reinstall Debian, Ubuntu, CentOS system with network.
## Suitable for using by GRUB.
## Blog: https://moeclub.org
## Written By Vicer

export tmpVER=''
export tmpDIST=''
export tmpURL=''
export tmpWORD=''
export tmpMirror=''
export tmpSSL=''
export tmpINS=''
export tmpFW=''
export ipAddr=''
export ipMask=''
export ipGate=''
export linuxdists=''
export ddMode='0'
export setNet='0'
export isMirror='0'
export FindDists='0'
export SpikCheckDIST='0'
export UNKNOWHW='0'
export UNVER='6.4'

while [[ $# -ge 1 ]]; do
  case $1 in
    -v|--ver)
      shift
      tmpVER="$1"
      shift
      ;;
    -d|--debian)
      shift
      linuxdists='debian'
      tmpDIST="$1"
      shift
      ;;
    -u|--ubuntu)
      shift
      linuxdists='ubuntu'
      tmpDIST="$1"
      shift
      ;;
    -c|--centos)
      shift
      linuxdists='centos'
      tmpDIST="$1"
      shift
      ;;
    -dd|--image)
      shift
      ddMode='1'
      tmpURL="$1"
      shift
      ;;
    -p|--password)
      shift
      tmpWORD="$1"
      shift
      ;;
    --ip-addr)
      shift
      ipAddr="$1"
      shift
      ;;
    --ip-mask)
      shift
      ipMask="$1"
      shift
      ;;
    --ip-gate)
      shift
      ipGate="$1"
      shift
      ;;
    -a|--auto)
      shift
      tmpINS='auto'
      ;;
    -m|--manual)
      shift
      tmpINS='manual'
      ;;
    -apt|-yum|--mirror)
      shift
      isMirror='1'
      tmpMirror="$1"
      shift
      ;;
    -ssl)
      shift
      tmpSSL="$1"
      shift
      ;;
    --firmware)
      shift
      tmpFW='1'
      ;;
    *)
      if [[ "$1" != 'error' ]]; then echo -ne "\nInvaild option: '$1'\n\n"; fi
      echo -ne " Usage:\n\tbash DebianNET.sh\t-d/--debian [\033[33m\033[04mdists-name\033[0m]\n\t\t\t\t-u/--ubuntu [\033[04mdists-name\033[0m]\n\t\t\t\t-c/--centos [\033[33m\033[04mdists-verison\033[0m]\n\t\t\t\t-v/--ver [32/\033[33m\033[04mi386\033[0m|64/amd64]\n\t\t\t\t--ip-addr/--ip-gate/--ip-mask\n\t\t\t\t-apt/-yum/--mirror\n\t\t\t\t-dd/--image\n\t\t\t\t-a/--auto\n\t\t\t\t-m/--manual\n"
      exit 1;
      ;;
    esac
  done

[[ "$EUID" -ne '0' ]] && echo "Error:This script must be run as root!" && exit 1;

function CheckDependence(){
FullDependence='0';
for BIN_DEP in `echo "$1" |sed 's/,/\n/g'`
  do
    if [[ -n "$BIN_DEP" ]]; then
      Founded='0';
      for BIN_PATH in `echo "$PATH" |sed 's/:/\n/g'`
        do
          ls $BIN_PATH/$BIN_DEP >/dev/null 2>&1;
          if [ $? == '0' ]; then
            Founded='1';
            break;
          fi
        done
      if [ "$Founded" == '1' ]; then
        echo -en "[\033[32mok\033[0m]\t";
      else
        FullDependence='1';
        echo -en "[\033[31mNot Install\033[0m]";
      fi
      echo -en "\t$BIN_DEP\n";
    fi
  done
if [ "$FullDependence" == '1' ]; then
  echo -ne "\n\033[31mError! \033[0mPlease use '\033[33mapt-get\033[0m' or '\033[33myum\033[0m' install it.\n\n\n"
  exit 1;
fi
}

if [[ -z "$linuxdists" ]]; then
  linuxdists='debian';
fi

clear && echo -e "\n\033[36m# Check Dependence\033[0m\n"

if [[ "$ddMode" == '1' ]]; then
  CheckDependence iconv;
  linuxdists='debian';
  tmpDIST='jessie';
  tmpVER='amd64';
  tmpINS='auto';
fi

if [[ "$linuxdists" == 'debian' ]] || [[ "$linuxdists" == 'ubuntu' ]]; then
  CheckDependence wget,awk,grep,sed,cut,cat,cpio,gzip,find,dirname,basename;
elif [[ "$linuxdists" == 'centos' ]]; then
  CheckDependence wget,awk,grep,sed,cut,cat,cpio,gzip,find,dirname,basename,file,xz;
fi

if [[ -n "$tmpWORD" ]]; then
  CheckDependence openssl;
fi

[[ -f '/boot/grub/grub.cfg' ]] && GRUBOLD='0' && GRUBDIR='/boot/grub' && GRUBFILE='grub.cfg';
[[ -z "$GRUBDIR" ]] && [[ -f '/boot/grub2/grub.cfg' ]] && GRUBOLD='0' && GRUBDIR='/boot/grub2' && GRUBFILE='grub.cfg';
[[ -z "$GRUBDIR" ]] && [[ -f '/boot/grub/grub.conf' ]] && GRUBOLD='1' && GRUBDIR='/boot/grub' && GRUBFILE='grub.conf';
[ -z "$GRUBDIR" -o -z "$GRUBFILE" ] && echo -ne "Error! \nNot Found grub path.\n" && exit 1;

if [[ "$isMirror" == '1' ]]; then
  if [[ -n "$tmpMirror" ]]; then
    TMPMirrorHost="$(echo -n "$tmpMirror" |grep -Eo '.*\.(\w+)')";
    echo "$TMPMirrorHost" |grep -q '://';
    if [[ $? == '0' ]]; then
      MirrorHost="$(echo "$TMPMirrorHost" |awk -F'://' '{print $2}')";
    else
      echo -en "\n\033[31mInvaild Mirror! \033[0m\n";
      [[ "$linuxdists" == 'debian' ]] && echo -en "\033[33mexample:\033[0m http://httpredir.debian.org/debian\n\n";
      [[ "$linuxdists" == 'ubuntu' ]] && echo -en "\033[33mexample:\033[0m http://archive.ubuntu.com/ubuntu\n\n";
      [[ "$linuxdists" == 'centos' ]] && echo -en "\033[33mexample:\033[0m http://mirror.centos.org/centos\n\n";
      exit 1
    fi
    if [[ -n "$MirrorHost" ]]; then
      MirrorFolder="$(echo -n "$tmpMirror" |awk -F''${MirrorHost}'' '{print $2}' |sed 's/\/$//g')";
      if [[ -z "$MirrorFolder" ]]; then
        [[ "$linuxdists" == 'debian' ]] && MirrorFolder='/debian';
        [[ "$linuxdists" == 'ubuntu' ]] && MirrorFolder='/ubuntu';
        [[ "$linuxdists" == 'centos' ]] && MirrorFolder='/centos';
      fi
      DISTMirror="${MirrorHost}${MirrorFolder}";
    fi
  fi
fi

if [[ -z "$DISTMirror" ]]; then
  [[ "$linuxdists" == 'debian' ]] && MirrorHost='httpredir.debian.org' && MirrorFolder='/debian' && DISTMirror="${MirrorHost}${MirrorFolder}";
  [[ "$linuxdists" == 'ubuntu' ]] && MirrorHost='archive.ubuntu.com' && MirrorFolder='/ubuntu' && DISTMirror="${MirrorHost}${MirrorFolder}";
  [[ "$linuxdists" == 'centos' ]] && DISTMirror='vault.centos.org';
fi

if [[ -n "$tmpVER" ]]; then
  tmpVER="$(echo "$tmpVER" |sed -r 's/(.*)/\L\1/')";
  if  [[ "$tmpVER" == '32' ]] || [[ "$tmpVER" == 'i386' ]] || [[ "$tmpVER" == 'x86' ]]; then
    VER='i386';
  fi
  if  [[ "$tmpVER" == '64' ]] || [[ "$tmpVER" == 'amd64' ]] || [[ "$tmpVER" == 'x86_64' ]] || [[ "$tmpVER" == 'x64' ]]; then
    if [[ "$linuxdists" == 'debian' ]] || [[ "$linuxdists" == 'ubuntu' ]]; then
      VER='amd64';
    elif [[ "$linuxdists" == 'centos' ]]; then
      VER='x86_64';
    fi
  fi
fi

if [[ -z "$VER" ]]; then
  VER='i386';
fi

if [[ -z "$tmpDIST" ]]; then
  [[ "$linuxdists" == 'debian' ]] && DIST='jessie';
  [[ "$linuxdists" == 'ubuntu' ]] && DIST='xenial';
  [[ "$linuxdists" == 'centos' ]] && DIST='6.8';
fi

if [[ -z "$DIST" ]]; then
  if [[ "$linuxdists" == 'debian' ]]; then
    SpikCheckDIST='0'
    DIST="$(echo "$tmpDIST" |sed -r 's/(.*)/\L\1/')";
    echo "$DIST" |grep -q '[0-9]';
    [[ $? -eq '0' ]] && {
      isDigital="$(echo "$DIST" |grep -o '[\.0-9]\{1,\}' |sed -n '1h;1!H;$g;s/\n//g;$p' |cut -d'.' -f1)";
      [[ -n $isDigital ]] && {
        [[ "$isDigital" == '7' ]] && DIST='wheezy';
        [[ "$isDigital" == '8' ]] && DIST='jessie';
        [[ "$isDigital" == '9' ]] && DIST='stretch';
        [[ "$isDigital" == '10' ]] && DIST='buster';
      }
    }
  fi
  if [[ "$linuxdists" == 'ubuntu' ]]; then
    SpikCheckDIST='0'
    DIST="$(echo "$tmpDIST" |sed -r 's/(.*)/\L\1/')";
    echo "$DIST" |grep -q '[0-9]';
    [[ $? -eq '0' ]] && {
      isDigital="$(echo "$DIST" |grep -o '[\.0-9]\{1,\}' |sed -n '1h;1!H;$g;s/\n//g;$p')";
      [[ -n $isDigital ]] && {
        [[ "$isDigital" == '12.04' ]] && DIST='precise';
        [[ "$isDigital" == '14.04' ]] && DIST='trusty';
        [[ "$isDigital" == '16.04' ]] && DIST='xenial';
        [[ "$isDigital" == '18.04' ]] && DIST='bionic';
      }
    }
  fi
  if [[ "$linuxdists" == 'centos' ]]; then
    SpikCheckDIST='1'
    DISTCheck="$(echo "$tmpDIST" |grep -o '[\.0-9]\{1,\}')";
    ListDIST="$(wget --no-check-certificate -qO- "http://$DISTMirror/dir_sizes" |cut -f2 |grep '^[0-9]')"
    DIST="$(echo "$ListDIST" |grep "^$DISTCheck")"
    [[ -z "$DIST" ]] && {
      echo -ne '\nThe dists version not found in this mirror, Please check it! \n\n'
      bash $0 error;
      exit 1;
    }
    wget --no-check-certificate -qO- "http://$DISTMirror/$DIST/os/$VER/.treeinfo" |grep -q 'general';
    [[ $? != '0' ]] && {
      echo -ne "\nThe version not found in this mirror, Please change mirror try again! \n\n";
      exit 1;
    }

  fi
fi

if [[ "$SpikCheckDIST" == '0' ]]; then
  DistsList="$(wget --no-check-certificate -qO- "http://$DISTMirror/dists/" |grep -o 'href=.*/"' |cut -d'"' -f2 |sed '/-\|old\|Debian\|experimental\|stable\|test\|sid\|devel/d' |grep '^[^/]' |sed -n '1h;1!H;$g;s/\n//g;s/\//\;/g;$p')";
  for CheckDEB in `echo "$DistsList" |sed 's/;/\n/g'`
    do
      [[ "$CheckDEB" == "$DIST" ]] && FindDists='1';
      [[ "$FindDists" == '1' ]] && break;
    done
  [[ "$FindDists" == '0' ]] && {
    echo -ne '\nThe dists version not found, Please check it! \n\n'
    bash $0 error;
    exit 1;
  }
fi

[[ "$ddMode" == '1' ]] && {
  export SSL_SUPPORT='https://moeclub.org/get-wget_udeb_amd64';
  if [[ -n "$tmpURL" ]]; then
    DDURL="$tmpURL"
    echo "$DDURL" |grep -q '^http://\|^ftp://\|^https://';
    [[ $? -ne '0' ]] && echo 'Please input vaild URL,Only support http://, ftp:// and https:// !' && exit 1;
    [[ -n "$tmpSSL" ]] && SSL_SUPPORT="$tmpSSL";
  else
    echo 'Please input vaild image URL! ';
    exit 1;
  fi
}

[[ -n "$tmpINS" ]] && {
  [[ "$tmpINS" == 'auto' ]] && inVNC='n';
  [[ "$tmpINS" == 'manual' ]] && inVNC='y';
}

[ -n "$ipAddr" ] && [ -n "$ipMask" ] && [ -n "$ipGate" ] && setNet='1';
[[ -n "$tmpWORD" ]] && myPASSWORD="$(openssl passwd -1 "$tmpWORD")";
[[ -z "$myPASSWORD" ]] && myPASSWORD='$1$0shYGfBd$8v189JOozDO1jPqPO645e1';
[[ -n "$tmpFW" ]] && INCFW="$tmpFW";
[[ -z "$INCFW" ]] && INCFW='0';

clear && echo -e "\n\033[36m# Install\033[0m\n"

ASKVNC(){
  inVNC='y';
  [[ "$ddMode" == '0' ]] && {
    echo -ne "\033[34mCan you login VNC?\033[0m\e[33m[\e[32my\e[33m/n]\e[0m "
    read tmpinVNC
    [[ -n "$inVNCtmp" ]] && inVNC="$tmpinVNC"
  }
  [ "$inVNC" == 'y' -o "$inVNC" == 'Y' ] && inVNC='y';
  [ "$inVNC" == 'n' -o "$inVNC" == 'N' ] && inVNC='n';
}

[ "$inVNC" == 'y' -o "$inVNC" == 'n' ] || ASKVNC;
[[ "$linuxdists" == 'debian' ]] && LinuxName='Debian';
[[ "$linuxdists" == 'ubuntu' ]] && LinuxName='Ubuntu';
[[ "$linuxdists" == 'centos' ]] && LinuxName='CentOS';
[[ "$ddMode" == '0' ]] && { 
  [[ "$inVNC" == 'y' ]] && echo -e "\033[34mManual Mode\033[0m insatll \033[33m$LinuxName\033[0m [\033[33m$DIST\033[0m] [\033[33m$VER\033[0m] in VNC. "
  [[ "$inVNC" == 'n' ]] && echo -e "\033[34mAuto Mode\033[0m insatll \033[33m$LinuxName\033[0m [\033[33m$DIST\033[0m] [\033[33m$VER\033[0m]. "
}
[[ "$ddMode" == '1' ]] && {
  echo -ne "\033[34mAuto Mode\033[0m insatll \033[33mWindows\033[0m\n[\033[33m$DDURL\033[0m]\n"
}

if [[ "$linuxdists" == 'centos' ]]; then
  if [[ "$DIST" != "$UNVER" ]]; then
    awk 'BEGIN{print '${UNVER}'-'${DIST}'}' |grep -q '^-'
    if [ $? != '0' ]; then
      UNKNOWHW='1';
      echo -en "\033[33mThe version lower then \033[31m$UNVER\033[33m may not support in auto mode! \033[0m\n";
      if [[ "$inVNC" == 'n' ]]; then
        echo -en "\033[35mYou can connect VNC with \033[32mPublic IP\033[35m and port \033[32m1\033[35m/\033[32m5901\033[35m in vnc viewer.\033[0m\n"
        read -n 1 -p "Press Enter to continue..." INP
        [[ "$INP" != '' ]] && echo -ne '\b \n\n';
      fi
    fi
    awk 'BEGIN{print '${UNVER}'-'${DIST}'+0.59}' |grep -q '^-'
    if [ $? == '0' ]; then
      echo -en "\n\033[31mThe version higher then \033[33m6.9 \033[31mis not support in current! \033[0m\n\n"
      exit 1;
    fi
  fi
fi

echo -e "\n[\033[33m$LinuxName\033[0m] [\033[33m$DIST\033[0m] [\033[33m$VER\033[0m] Downloading..."

[[ -z "$DISTMirror" ]] && echo -ne "\033[31mError! \033[0mInvaild mirror! \n" && exit 1

if [[ "$linuxdists" == 'debian' ]] || [[ "$linuxdists" == 'ubuntu' ]]; then
wget --no-check-certificate -qO '/boot/initrd.img' "http://$DISTMirror/dists/$DIST/main/installer-$VER/current/images/netboot/$linuxdists-installer/$VER/initrd.gz"
[[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'initrd.img' for \033[33m$linuxdists\033[0m failed! \n" && exit 1
wget --no-check-certificate -qO '/boot/vmlinuz' "http://$DISTMirror/dists/$DIST/main/installer-$VER/current/images/netboot/$linuxdists-installer/$VER/linux"
[[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'vmlinuz' for \033[33m$linuxdists\033[0m failed! \n" && exit 1
elif [[ "$linuxdists" == 'centos' ]]; then
wget --no-check-certificate -qO '/boot/initrd.img' "http://$DISTMirror/$DIST/os/$VER/isolinux/initrd.img"
[[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'initrd.img' for \033[33m$linuxdists\033[0m failed! \n" && exit 1
wget --no-check-certificate -qO '/boot/vmlinuz' "http://$DISTMirror/$DIST/os/$VER/isolinux/vmlinuz"
[[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'vmlinuz' for \033[33m$linuxdists\033[0m failed! \n" && exit 1
fi
if [[ "$linuxdists" == 'debian' ]]; then
  if [[ "$INCFW" == '1' ]]; then
    wget --no-check-certificate -qO '/boot/firmware.cpio.gz' "http://cdimage.debian.org/cdimage/unofficial/non-free/firmware/$DIST/current/firmware.cpio.gz"
    [[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'firmware' for \033[33m$linuxdists\033[0m failed! \n" && exit 1
  fi
fi

[[ "$setNet" == '1' ]] && {
  IPv4="$ipAddr";
  MASK="$ipMask";
  GATE="$ipGate";
} || {
  DEFAULTNET="$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.*' |head -n1 |sed 's/proto.*\|onlink.*//g' |awk '{print $NF}')";
  [[ -n "$DEFAULTNET" ]] && IPSUB="$(ip addr |grep ''${DEFAULTNET}'' |grep 'global' |grep 'brd' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}/[0-9]\{1,2\}')";
  IPv4="$(echo -n "$IPSUB" |cut -d'/' -f1)";
  NETSUB="$(echo -n "$IPSUB" |grep -o '/[0-9]\{1,2\}')";
  GATE="$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}')";
  [[ -n "$NETSUB" ]] && MASK="$(echo -n '128.0.0.0/1,192.0.0.0/2,224.0.0.0/3,240.0.0.0/4,248.0.0.0/5,252.0.0.0/6,254.0.0.0/7,255.0.0.0/8,255.128.0.0/9,255.192.0.0/10,255.224.0.0/11,255.240.0.0/12,255.248.0.0/13,255.252.0.0/14,255.254.0.0/15,255.255.0.0/16,255.255.128.0/17,255.255.192.0/18,255.255.224.0/19,255.255.240.0/20,255.255.248.0/21,255.255.252.0/22,255.255.254.0/23,255.255.255.0/24,255.255.255.128/25,255.255.255.192/26,255.255.255.224/27,255.255.255.240/28,255.255.255.248/29,255.255.255.252/30,255.255.255.254/31,255.255.255.255/32' |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'${NETSUB}'' |cut -d'/' -f1)";
}

[[ -n "$GATE" ]] && [[ -n "$MASK" ]] && [[ -n "$IPv4" ]] || {
echo "Not found \`ip command\`, It will use \`route command\`."
ipNum() {
  local IFS='.';
  read ip1 ip2 ip3 ip4 <<<"$1";
  echo $((ip1*(1<<24)+ip2*(1<<16)+ip3*(1<<8)+ip4));
}

SelectMax(){
ii=0;
for IPITEM in `route -n |awk -v OUT=$1 '{print $OUT}' |grep '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'`
  do
    NumTMP="$(ipNum $IPITEM)";
    eval "arrayNum[$ii]='$NumTMP,$IPITEM'";
    ii=$[$ii+1];
  done
echo ${arrayNum[@]} |sed 's/\s/\n/g' |sort -n -k 1 -t ',' |tail -n1 |cut -d',' -f2;
}

[[ -z $IPv4 ]] && IPv4="$(ifconfig |grep 'Bcast' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}' |head -n1)";
[[ -z $GATE ]] && GATE="$(SelectMax 2)";
[[ -z $MASK ]] && MASK="$(SelectMax 3)";

[[ -n "$GATE" ]] && [[ -n "$MASK" ]] && [[ -n "$IPv4" ]] || {
  echo "Error! Not configure network. ";
  exit 1;
}
}

[[ "$setNet" != '1' ]] && [[ -f '/etc/network/interfaces' ]] && {
  [[ -z "$(sed -n '/iface.*inet static/p' /etc/network/interfaces)" ]] && AutoNet='1' || AutoNet='0';
  [[ -d /etc/network/interfaces.d ]] && {
    ICFGN="$(find /etc/network/interfaces.d -name '*.cfg' |wc -l)" || ICFGN='0';
    [[ "$ICFGN" -ne '0' ]] && {
      for NetCFG in `ls -1 /etc/network/interfaces.d/*.cfg`
        do 
          [[ -z "$(cat $NetCFG | sed -n '/iface.*inet static/p')" ]] && AutoNet='1' || AutoNet='0';
          [[ "$AutoNet" -eq '0' ]] && break;
        done
    }
  }
}

[[ "$setNet" != '1' ]] && [[ -d '/etc/sysconfig/network-scripts' ]] && {
  ICFGN="$(find /etc/sysconfig/network-scripts -name 'ifcfg-*' |grep -v 'lo'|wc -l)" || ICFGN='0';
  [[ "$ICFGN" -ne '0' ]] && {
    for NetCFG in `ls -1 /etc/sysconfig/network-scripts/ifcfg-* |grep -v 'lo$' |grep -v ':[0-9]\{1,\}'`
      do 
        [[ -n "$(cat $NetCFG | sed -n '/BOOTPROTO.*[dD][hH][cC][pP]/p')" ]] && AutoNet='1' || {
          AutoNet='0' && . $NetCFG;
          [[ -n $NETMASK ]] && MASK="$NETMASK";
          [[ -n $GATEWAY ]] && GATE="$GATEWAY";
        }
        [[ "$AutoNet" -eq '0' ]] && break;
      done
  }
}

[[ ! -f $GRUBDIR/$GRUBFILE ]] && echo "Error! Not Found $GRUBFILE. " && exit 1;

[[ ! -f $GRUBDIR/$GRUBFILE.old ]] && [[ -f $GRUBDIR/$GRUBFILE.bak ]] && mv -f $GRUBDIR/$GRUBFILE.bak $GRUBDIR/$GRUBFILE.old;
mv -f $GRUBDIR/$GRUBFILE $GRUBDIR/$GRUBFILE.bak;
[[ -f $GRUBDIR/$GRUBFILE.old ]] && cat $GRUBDIR/$GRUBFILE.old >$GRUBDIR/$GRUBFILE || cat $GRUBDIR/$GRUBFILE.bak >$GRUBDIR/$GRUBFILE;

[[ "$GRUBOLD" == '0' ]] && {
  READGRUB='/tmp/grub.read'
  cat $GRUBDIR/$GRUBFILE |sed -n '1h;1!H;$g;s/\n/%%%%%%%/g;$p' |grep -om 1 'menuentry\ [^{]*{[^}]*}%%%%%%%' |sed 's/%%%%%%%/\n/g' >$READGRUB
  LoadNum="$(cat $READGRUB |grep -c 'menuentry ')"
  if [[ "$LoadNum" -eq '1' ]]; then
    cat $READGRUB |sed '/^$/d' >/tmp/grub.new;
  elif [[ "$LoadNum" -gt '1' ]]; then
    CFG0="$(awk '/menuentry /{print NR}' $READGRUB|head -n 1)";
    CFG2="$(awk '/menuentry /{print NR}' $READGRUB|head -n 2 |tail -n 1)";
    CFG1="";
    for tmpCFG in `awk '/}/{print NR}' $READGRUB`
      do
        [ "$tmpCFG" -gt "$CFG0" -a "$tmpCFG" -lt "$CFG2" ] && CFG1="$tmpCFG";
      done
    [[ -z "$CFG1" ]] && {
      echo "Error! read $GRUBFILE. ";
      exit 1;
    }

    sed -n "$CFG0,$CFG1"p $READGRUB >/tmp/grub.new;
    [[ -f /tmp/grub.new ]] && [[ "$(grep -c '{' /tmp/grub.new)" -eq "$(grep -c '}' /tmp/grub.new)" ]] || {
      echo -ne "\033[31mError! \033[0mNot configure $GRUBFILE. \n";
      exit 1;
    }
  fi
  [ ! -f /tmp/grub.new ] && echo "Error! $GRUBFILE. " && exit 1;
  sed -i "/menuentry.*/c\menuentry\ \'Install OS \[$DIST\ $VER\]\'\ --class debian\ --class\ gnu-linux\ --class\ gnu\ --class\ os\ \{" /tmp/grub.new
  sed -i "/echo.*Loading/d" /tmp/grub.new;
  INSERTGRUB="$(awk '/menuentry /{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
}

[[ "$GRUBOLD" == '1' ]] && {
  CFG0="$(awk '/title /{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)";
  CFG1="$(awk '/title /{print NR}' $GRUBDIR/$GRUBFILE|head -n 2 |tail -n 1)";
  [[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 == $CFG0 ] && sed -n "$CFG0,$"p $GRUBDIR/$GRUBFILE >/tmp/grub.new;
  [[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 != $CFG0 ] && sed -n "$CFG0,$CFG1"p $GRUBDIR/$GRUBFILE >/tmp/grub.new;
  [[ ! -f /tmp/grub.new ]] && echo "Error! configure append $GRUBFILE. " && exit 1;
  sed -i "/title.*/c\title\ \'Install OS \[$DIST\ $VER\]\'" /tmp/grub.new;
  sed -i '/^#/d' /tmp/grub.new;
  INSERTGRUB="$(awk '/title /{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
}

[[ -n "$(grep 'linux.*/\|kernel.*/' /tmp/grub.new |awk '{print $2}' |tail -n 1 |grep '^/boot/')" ]] && Type='InBoot' || Type='NoBoot';

LinuxKernel="$(grep 'linux.*/\|kernel.*/' /tmp/grub.new |awk '{print $1}' |head -n 1)";
[[ -z "$LinuxKernel" ]] && echo "Error! read grub config! " && exit 1;
LinuxIMG="$(grep 'initrd.*/' /tmp/grub.new |awk '{print $1}' |tail -n 1)";
[ -z "$LinuxIMG" ] && sed -i "/$LinuxKernel.*\//a\\\tinitrd\ \/" /tmp/grub.new && LinuxIMG='initrd';

if [[ "$linuxdists" == 'debian' ]] || [[ "$linuxdists" == 'ubuntu' ]]; then
  BOOT_OPTION="auto=true hostname=$linuxdists domain= -- quiet"
elif [[ "$linuxdists" == 'centos' ]]; then
  BOOT_OPTION="ks=file://ks.cfg ksdevice=link"
fi

[[ "$Type" == 'InBoot' ]] && {
  sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/boot\/vmlinuz $BOOT_OPTION" /tmp/grub.new;
  sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/boot\/initrd.img" /tmp/grub.new;
}

[[ "$Type" == 'NoBoot' ]] && {
  sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/vmlinuz $BOOT_OPTION" /tmp/grub.new;
  sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/initrd.img" /tmp/grub.new;
}

sed -i '$a\\n' /tmp/grub.new;

[[ "$inVNC" == 'n' ]] && {
GRUBPATCH='0';

[ -f '/etc/network/interfaces' -o -d '/etc/sysconfig/network-scripts' ] || {
  echo "Error, Not found interfaces config.";
  exit 1;
}

sed -i ''${INSERTGRUB}'i\\n' $GRUBDIR/$GRUBFILE;
sed -i ''${INSERTGRUB}'r /tmp/grub.new' $GRUBDIR/$GRUBFILE;
[[ -f  $GRUBDIR/grubenv ]] && sed -i 's/saved_entry/#saved_entry/g' $GRUBDIR/grubenv;

[[ -d /boot/tmp ]] && rm -rf /boot/tmp;
mkdir -p /boot/tmp;
cd /boot/tmp;
if [[ "$linuxdists" == 'debian' ]] || [[ "$linuxdists" == 'ubuntu' ]]; then
  COMPTYPE="gzip";
elif [[ "$linuxdists" == 'centos' ]]; then
  COMPTYPE="$(file /boot/initrd.img |grep -o ':.*compressed data' |cut -d' ' -f2 |sed -r 's/(.*)/\L\1/' |head -n1)"
  [[ -z "$COMPTYPE" ]] && echo "Detect compressed type fail." && exit 1;
fi
CompDected='0'
for ListCOMP in `echo -en 'gzip\nlzma\nxz'`
  do
    if [[ "$COMPTYPE" == "$ListCOMP" ]]; then
      CompDected='1'
      if [[ "$COMPTYPE" == 'gzip' ]]; then
        NewIMG="initrd.img.gz"
      else
        NewIMG="initrd.img.$COMPTYPE"
      fi
      mv -f "/boot/initrd.img" "/boot/$NewIMG"
      break;
    fi
  done
[[ "$CompDected" != '1' ]] && echo "Detect compressed type not support." && exit 1;
[[ "$COMPTYPE" == 'lzma' ]] && UNCOMP='xz --format=lzma --decompress';
[[ "$COMPTYPE" == 'xz' ]] && UNCOMP='xz --decompress';
[[ "$COMPTYPE" == 'gzip' ]] && UNCOMP='gzip -d';

$UNCOMP < ../$NewIMG | cpio --extract --verbose --make-directories --no-absolute-filenames >>/dev/null 2>&1

if [[ "$linuxdists" == 'debian' ]] || [[ "$linuxdists" == 'ubuntu' ]]; then
cat >/boot/tmp/preseed.cfg<<EOF
d-i debian-installer/locale string en_US
d-i console-setup/layoutcode string us

d-i keyboard-configuration/xkb-keymap string us

d-i netcfg/choose_interface select auto

d-i netcfg/disable_autoconfig boolean true
d-i netcfg/dhcp_failed note
d-i netcfg/dhcp_options select Configure network manually
d-i netcfg/get_ipaddress string $IPv4
d-i netcfg/get_netmask string $MASK
d-i netcfg/get_gateway string $GATE
d-i netcfg/get_nameservers string 8.8.8.8
d-i netcfg/no_default_route boolean true
d-i netcfg/confirm_static boolean true

d-i hw-detect/load_firmware boolean true

d-i mirror/country string manual
d-i mirror/http/hostname string $MirrorHost
d-i mirror/http/directory string $MirrorFolder
d-i mirror/http/proxy string

d-i passwd/root-login boolean ture
d-i passwd/make-user boolean false
d-i passwd/root-password-crypted password $myPASSWORD
d-i user-setup/allow-password-weak boolean true
d-i user-setup/encrypt-home boolean false

d-i clock-setup/utc boolean true
d-i time/zone string US/Eastern
d-i clock-setup/ntp boolean true

d-i preseed/early_command string anna-install libfuse2-udeb fuse-udeb ntfs-3g-udeb fuse-modules-3.16.0-4-amd64-di
d-i partman/early_command string \
debconf-set partman-auto/disk "\$(list-devices disk |head -n1)"; \
wget -qO- '$DDURL' |gunzip -dc |/bin/dd of=\$(list-devices disk |head -n1); \
mount.ntfs-3g \$(list-devices partition |head -n1) /mnt; \
cd '/mnt/ProgramData/Microsoft/Windows/Start Menu/Programs'; \
cd Start* || cd start*; \
cp -f '/net.bat' './net.bat'; \
/sbin/reboot; \
debconf-set grub-installer/bootdev string "\$(list-devices disk |head -n1)"; \
umount /media || true; \

d-i partman/mount_style select uuid
d-i partman-auto/init_automatically_partition select Guided - use entire disk
d-i partman-auto/method string regular
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

d-i debian-installer/allow_unauthenticated boolean true

tasksel tasksel/first multiselect minimal
d-i pkgsel/update-policy select none
d-i pkgsel/include string openssh-server
d-i pkgsel/upgrade select none

popularity-contest popularity-contest/participate boolean false

d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string default
d-i finish-install/reboot_in_progress note
d-i debian-installer/exit/reboot boolean true
d-i preseed/late_command string	\
sed -ri 's/^#?PermitRootLogin.*/PermitRootLogin yes/g' /target/etc/ssh/sshd_config; \
sed -ri 's/^#?PasswordAuthentication.*/PasswordAuthentication yes/g' /target/etc/ssh/sshd_config;
EOF

[[ "$setNet" == '0' ]] && [[ "$AutoNet" == '1' ]] && {
  sed -i '/netcfg\/disable_autoconfig/d' /boot/tmp/preseed.cfg
  sed -i '/netcfg\/dhcp_options/d' /boot/tmp/preseed.cfg
  sed -i '/netcfg\/get_.*/d' /boot/tmp/preseed.cfg
  sed -i '/netcfg\/confirm_static/d' /boot/tmp/preseed.cfg
}

[[ "$DIST" == 'trusty' ]] && GRUBPATCH='1'
[[ "$DIST" == 'wily' ]] && GRUBPATCH='1'

[[ "$GRUBPATCH" == '1' ]] && {
  sed -i 's/^d-i\ grub-installer\/bootdev\ string\ default//g' /boot/tmp/preseed.cfg
}
[[ "$GRUBPATCH" == '0' ]] && {
  sed -i 's/debconf-set\ grub-installer\/bootdev.*\"\;//g' /boot/tmp/preseed.cfg
}
[[ "$DIST" == 'xenial' ]] && {
  sed -i 's/^d-i\ clock-setup\/ntp\ boolean\ true/d-i\ clock-setup\/ntp\ boolean\ false/g' /boot/tmp/preseed.cfg
}

[[ "$linuxdists" == 'debian' ]] && {
  sed -i '/user-setup\/allow-password-weak/d' /boot/tmp/preseed.cfg
  sed -i '/user-setup\/encrypt-home/d' /boot/tmp/preseed.cfg
  sed -i '/pkgsel\/update-policy/d' /boot/tmp/preseed.cfg
  sed -i 's/umount\ \/media.*true\;\ //g' /boot/tmp/preseed.cfg
}
[[ "$INCFW" == '1' ]] && [[ "$linuxdists" == 'debian' ]] && [[ -f '/boot/firmware.cpio.gz' ]] && {
  gzip -d < ../firmware.cpio.gz | cpio --extract --verbose --make-directories --no-absolute-filenames >>/dev/null 2>&1
}

[[ "$ddMode" == '1' ]] && {
WinDHCP(){
  echo -ne "@ECHO OFF\r\ncd\040\057d\040\042\045ProgramData\045\057Microsoft\057Windows\057Start\040Menu\057Programs\057Startup\042\r\ndel\040\057f\040\057q\040net\056bat\r\n\r\n" >'/boot/tmp/net.tmp';
}
WinNoDHCP(){
  echo -ne "@ECHO OFF\r\ncd\056\076\045windir\045\GetAdmin\r\nif\040exist\040\045windir\045\GetAdmin\040\050del\040\057f\040\057q\040\042\045windir\045\GetAdmin\042\051\040else\040\050\r\necho\040CreateObject^\050\042Shell\056Application\042^\051\056ShellExecute\040\042\045~s0\042\054\040\042\045\052\042\054\040\042\042\054\040\042runas\042\054\040\061\040\076\076\040\042\045temp\045\Admin\056vbs\042\r\n\042\045temp\045\Admin\056vbs\042\r\ndel\040\057f\040\057q\040\042\045temp\045\Admin\056vbs\042\r\nexit\040\057b\040\062\051\r\nfor\040\057f\040\042tokens=\063\052\042\040\045\045i\040in\040\050\047netsh\040interface\040show\040interface\040^|more\040+3\040^|findstr\040\057R\040\042\u672c\u5730\056\052\040\u4ee5\u592a\056\052\040Local\056\052\040Ethernet\042\047\051\040do\040\050set\040EthName=\045\045j\051\r\nnetsh\040-c\040interface\040ip\040set\040address\040name=\042\045EthName\045\042\040source=static\040address=$IPv4\040mask=$MASK\040gateway=$GATE\r\nnetsh\040-c\040interface\040ip\040add\040dnsservers\040name=\042\045EthName\045\042\040address=\070\056\070\056\070\056\070\040index=1\040validate=no\r\nnetsh\040-c\040interface\040ip\040add\040dnsservers\040name=\042\045EthName\045\042\040address=\070\056\070\056\064\056\064\040index=2\040validate=no\r\ncd\040\057d\040\042\045ProgramData\045\057Microsoft\057Windows\057Start\040Menu\057Programs\057Startup\042\r\ndel\040\057f\040\057q\040net\056bat\r\n\r\n" >'/boot/tmp/net.tmp';
}
  [[ "$setNet" == '1' ]] && WinNoDHCP;
  [[ "$setNet" == '0' ]] && {
    [[ "$AutoNet" -eq '1' ]] && WinDHCP;
    [[ "$AutoNet" -eq '0' ]] && WinNoDHCP;
  }
  iconv -f 'UTF-8' -t 'GBK' '/boot/tmp/net.tmp' -o '/boot/tmp/net.bat'
  rm -rf '/boot/tmp/net.tmp'
  echo "$DDURL" |grep -q '^https://'
  [[ $? -eq '0' ]] && {
    echo -ne '\nAdd ssl support...\n'
    [[ -n $SSL_SUPPORT ]] && {
      wget --no-check-certificate -qO- "$SSL_SUPPORT" |tar -x
      [[ ! -f  /boot/tmp/usr/bin/wget ]] && echo 'Error! SSL_SUPPORT.' && exit 1;
      sed -i 's/wget\ -qO-/\/usr\/bin\/wget\ --no-check-certificate\ --retry-connrefused\ --tries=7\ --continue\ -qO-/g' /boot/tmp/preseed.cfg
      [[ $? -eq '0' ]] && echo -ne 'Success! \n\n'
    } || {
    echo -ne 'Not ssl support package! \n\n';
    exit 1;
    }
  }
}

[[ "$ddMode" == '0' ]] && {
  sed -i '/anna-install/d' /boot/tmp/preseed.cfg
  sed -i 's/wget.*\/sbin\/reboot\;\ //g' /boot/tmp/preseed.cfg
}

elif [[ "$linuxdists" == 'centos' ]]; then
cat >/boot/tmp/ks.cfg<<EOF
#platform=x86, AMD64, or Intel EM64T
firewall --enabled --ssh
install
url --url="http://$DISTMirror/$DIST/os/$VER/"
rootpw --iscrypted $myPASSWORD
auth --useshadow --passalgo=sha512
firstboot --disable
lang en_US
keyboard us
selinux --disabled
logging --level=info
reboot
text
unsupported_hardware
vnc
skipx
timezone --isUtc Asia/Hong_Kong
#ONDHCP network --bootproto=dhcp --onboot=on
#NODHCP network --bootproto=static --ip=$IPv4 --netmask=$MASK --gateway=$GATE --nameserver=8.8.8.8 --onboot=on
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel 
autopart

%packages
@base
%end

%post --interpreter=/bin/bash
rm -rf /root/anaconda-ks.cfg
rm -rf /root/install.*log
%end

EOF

[[ "$setNet" == '0' ]] && [[ "$AutoNet" == '1' ]] && {
  sed -i 's/#ONDHCP\ //g' /boot/tmp/ks.cfg
} || {
  sed -i 's/#NODHCP\ //g' /boot/tmp/ks.cfg
}
[[ "$UNKNOWHW" == '1' ]] && sed -i 's/^unsupported_hardware/#unsupported_hardware/g' /boot/tmp/ks.cfg
[[ "$(echo "$DIST" |grep -o '^[0-9]\{1\}')" == '5' ]] && sed -i '0,/^%end/s//#%end/' /boot/tmp/ks.cfg
fi

rm -rf ../initrd.img;
find . | cpio -H newc --create --verbose | gzip -9 > ../initrd.img;
rm -rf /boot/tmp;
}

[[ "$inVNC" == 'y' ]] && {
  sed -i '$i\\n' $GRUBDIR/$GRUBFILE
  sed -i '$r /tmp/grub.new' $GRUBDIR/$GRUBFILE
  echo -e "\n\033[33m\033[04mIt will reboot! \nPlease look at VNC! \nSelect\033[0m\033[32m Install OS [$DIST $VER] \033[33m\033[4mto install system.\033[04m\n\n\033[31m\033[04mThere is some information for you.\nDO NOT CLOSE THE WINDOW! \033[0m\n"
  echo -e "\033[35mIPv4\t\tNETMASK\t\tGATEWAY\033[0m"
  echo -e "\033[36m\033[04m$IPv4\033[0m\t\033[36m\033[04m$MASK\033[0m\t\033[36m\033[04m$GATE\033[0m\n\n"

  read -n 1 -p "Press Enter to reboot..." INP
  [[ "$INP" != '' ]] && echo -ne '\b \n\n';
}

chown root:root $GRUBDIR/$GRUBFILE
chmod 444 $GRUBDIR/$GRUBFILE

sleep 3 && reboot >/dev/null 2>&1
