#!/bin/bash

# Define function to show menu
show_menu() {
    echo "Select an option:"
    echo "1. View open ports"
    echo "2. Add IP address"
    echo "3. Flush port"
    echo "4. Exit"
}

# Define function to view open ports
view_ports() {
  if [[ $1 == "all" ]]; then
    sudo iptables -L -n | grep "ACCEPT" | grep "tcp" | awk '{print "IP Range: "$4"\tPort: "$11}'
  else
    sudo iptables -L -n | grep "ACCEPT" | grep "tcp" | grep ":$1 " | awk '{print "IP Range: "$4"\tPort: "$11}'
  fi
}

# Define function to add IP address
add_ip() {
    sudo iptables -A INPUT -p tcp --dport $1 -s $2 -j ACCEPT
}

# Define function to flush port
flush_port() {
    sudo iptables -D INPUT -p tcp --dport $1 -j ACCEPT
}

# Show menu and get user input
show_menu
read -p "Enter your choice: " choice

# Process user choice
while [[ $choice != 4 ]]; do
    case $choice in
        1)
            read -p "Enter port number to filter (or enter 'all' to show all open ports): " port
            view_ports $port
            ;;
        2)
            read -p "Enter port number: " port
            read -p "Enter IP address to add: " ip
            add_ip $port $ip
            ;;
        3)
            read -p "Enter port number to flush: " port
            flush_port $port
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
    show_menu
    read -p "Enter your choice: " choice
done

echo "Exiting..."```

Save this script as iptables-manager.sh and run it using the command: `bash iptables-manager.sh` 

Note: It's important to run this script as root or with sudo privileges because iptables requires root access to make changes to the firewall rules.