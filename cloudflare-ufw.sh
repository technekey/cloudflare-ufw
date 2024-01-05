#!/bin/sh


#this script is updated to do the following:
# If no arguments are passed to the script
# Then allow all the traffic on all ports from
# cloudflare IPs
# if a port or port list is passed then only those
# ports will be allowed.

# I am cleaning up the old cloudflare rules based on
# the comment, so any old IP/subnet will be cleaned
# before loading this.

#you may want to add this script to cron

reload_ufw() {
    ufw reload > /dev/null
}

clear_old_rules() {
    for i in $(ufw status numbered |awk '/Cloudflare/{x=gensub(/^\[([ ]*[0-9]+)\].*/,"\\1","g");print x}' |tac);do
        echo "y"|ufw delete $i
    done
}

allow_specific_ports_from_cloudflare() {
    for arg in "$@"; do
        # Append the argument to the CSV string
        port_list+=",$arg"
    done

    # Remove the leading comma
    port_list="${port_list:1}"
    echo "port_list: '$port_list'"
    for cfip in $(curl -sw '\n' https://www.cloudflare.com/ips-v{4,6}); do
        if [ "$port_list" == '' ];then
            ufw allow proto tcp from $cfip comment 'Cloudflare IP';
        else
            ufw allow proto tcp from $cfip to any port "$port_list" comment 'Cloudflare IP';
        fi
     done

}

#clear existing rules that have 'Cloudflare IP' as comments
clear_old_rules

#add the rules to allow Cloudflare IPs
allow_specific_ports_from_cloudflare $@

#reload the Firewall
reload_ufw
