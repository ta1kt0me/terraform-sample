# Ansible

build web server.

## Prepare

### ssh_config

Add private key in ssh-agent.

```
ssh-add ~/.ssh/sample.pem
```

Edit `~/.ssh/config`.

```
Host bastion
  HostName # set eip
  User ec2-user
  Port 22
  PasswordAuthentication no
  TCPKeepAlive yes
  ForwardAgent yes

Host sample_web
  HostName # set private ip
  User ubuntu
  Port 22
  PasswordAuthentication no
  TCPKeepAlive yes
  ForwardAgent yes
  ProxyCommand ssh -W %h:%p bastion
```

## Run

Exec after terraform

```
$ cd ansible
$ ansible-playbook -i aws playbook.yml
```
