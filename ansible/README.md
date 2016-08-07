# Setup web server

Setup web server with ansible

## Prepare

### ssh_config

Add private key in ssh-agent.

```
ssh-add ~/.ssh/sample.pem
```

## Run

Exec after executed terraform && complated ec2 instance setup.

```
$ cd ansible
$ ansible-playbook -i aws playbook.yml
```
