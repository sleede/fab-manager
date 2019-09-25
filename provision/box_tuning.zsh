#!/usr/bin/env zsh

###
# Tune-up the system settings
system_tuning()
{
  echo "Tunning up the system"

  # Enable overcomit memmory for Redis
  sudo echo -e "\n## Redis tune-up" >> /etc/sysctl.conf
  sudo echo '# Allow background save on low memory conditions' >> /etc/sysctl.conf
  sudo echo -e "vm.overcommit_memory = 1\n" >> /etc/sysctl.conf

  # Enagle huge pages for Redis
  sudo touch /etc/rc.local
  sudo echo '## Redis tune-up' >> /etc/rc.local
  sudo echo '# Reduce latency and memory usage' >> /etc/rc.local
  sudo echo 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.local
  sudo echo -e "\n\n"
  sudo echo -e "exit 0\n" >> /etc/rc.local
  sudo chmod +x /etc/rc.local

  # Increase virtual memory areas for ElasticSearch
  sudo echo -e "\n## ElasticSearch tune-up" >> /etc/sysctl.conf
  sudo echo '# Increase max virtual memory areas' >> /etc/sysctl.conf
  sudo echo -e "vm.max_map_count = 262144\n" >> /etc/sysctl.conf
}

setup() {
  system_tuning
}

setup "$@"

echo 'Virtual Environment is ready. Plase run `vagrant reload`.'