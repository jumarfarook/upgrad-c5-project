#from local
ansible-playbook install-ansible.yml -i inventory.yml -l bastion

# bastion host
ssh -A bastion-host "mkdir ansible"
scp *.yml bastion-host:/home/ubuntu/ansible/

# jenkins server
ssh -A bastion-host "ansible-playbook /home/ubuntu/ansible/install-docker.yml -i /home/ubuntu/ansible/inventory.yml -l jenkins"
ssh -A bastion-host "ansible-playbook /home/ubuntu/ansible/install-git.yml -i /home/ubuntu/ansible/inventory.yml -l jenkins"
ssh -A bastion-host "ansible-playbook /home/ubuntu/ansible/install-jenkins.yml -i /home/ubuntu/ansible/inventory.yml -l jenkins"

# app server
ssh -A bastion-host "ansible-playbook /home/ubuntu/ansible/install-docker.yml -i /home/ubuntu/ansible/inventory.yml -l app"