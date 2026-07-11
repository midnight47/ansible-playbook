ansible-playbook ./playbooks/roles_play/new_server.yml \
  --ask-pass \
  -u root \
  -e 'ansible_become=false'

