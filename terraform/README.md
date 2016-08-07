# Build aws

Build aws network via terraform.

## Prepare

- Create IAM user
- Create `sample` keypair
- Install direnv
  - add .envrc
  - Write `AWS_ACCESS_KEY_ID` & `AWS_SECRET_ACCESS_KEY`

### `.envrc` sample

```
AWS_ACCESS_KEY_ID=XXX
AWS_SECRET_ACCESS_KEY=XXX
```

## Run

```
$ cd terraform
$ terraform plan
$ terraform apply
```

## Network

- VPC(10.1.0.0/16)
  - Internet Gate Way
  - RouteTable for IGW
  - RouteTable for Nat
  - Public Subnet(10.1.1.0/24)
    - Nat Instance
      - EIP
	  - Security Group for Nat
    - ELB
      - Security Group for ELB
  - Private Subnet(10.1.2.0/24)
    - Web Instance
      - Security Group for Web
      - Role for awslogs
