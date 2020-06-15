# An example of AWS clusters-provisioning and monitoring with ICM and SAM automation

## Intro

This is an example of cloud provisioning of InterSystems IRIS clusters in four different AWS regions with [ICM](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GICM) and the automated configuration of [System Alerting and Monitoring or SAM](https://docs.intersystems.com/sam/csp/docbook/Doc.View.cls?KEY=ASAM), via its REST API.

This code was used for demos. Although it showcase the power of ICM and the flexibility of SAM and its REST API, it is intended as demoware for  
- ICM  
- SAM  
- container usage &  
- scripting solutions  

![SAM screenshot](img/#1-SAM-cluster-singlenodeissue.jpg)

### Production considerations 
For production environments the user must consider more attentively security, high availability and performance and review options like  
- a bastion  
  ```
  {
 	"Role": "VM",
	"Count": "1",
	"Bastion": "true"
    }
  ```  
- keep the backend services in a private subnet (note that this is automated for you if you ask for a bastion as above)
  ```
  "PrivateSubnet": "true"
  ```
- having adequate resources like
  - instance types
  - storage and
  - fault tolerant configurations
    ```
    {
      "Provider": "AWS",
      "Region": "us-west-1",
      "Zone": "us-west-1b,us-west-1c",
      "MachineType": "m5.8xlarge",
      "OSVolumeSize": "100",
      "DataVolumeSize": "50000",
      "Mirror": "true"
      ...
    ```
  - etc.


## Requirements to run the demo
- Have a local instance of [SAM already running](https://github.com/intersystems-community/sam)  

- Have the InterSystems Cloud Manager (ICM) container
  - please tune accordingly the ```env-config.sh``` script

- All variables declaration are in the script ```env-config.sh```. Make sure to use containers and credentials in accordance to your environment. The configuration variables deal with 
  - the ICM container tag name
  - SAM credentials and
  - a timeout  

- Credentials:  
  - AWS credentials must be provided in a file; you'll be asked to provide the file name. There is a default credentials file in the root directory called  ```aws.credentials```. Amend it accordingly.  
  - Docker Hub (or your registry) credentials are needed for ICM to pull containers from the registry to the various AWS regions. The registry must obviously be accessible from the AWS regions specified.
    - Edit the ```defaults.json``` file in each _AWS*_ subdirectory and override the dummy entries in the JSON keys:
      - ```DockerUsername``` and 
      - ```DockerPassword```
  - SAM credentials
    - Edit the variable ```SAMcredentials="_SYSTEM:myBestPassword"``` in the ```env-config.sh``` file as described above
     
- Keys & certificates
  - Temporary TLS certificates and ssh keys are generated at each run
  - InterSystems IRIS keys with sharding enabled must be provided in each *./AWSn-subdirectory/ikey/*
    - please make sure to specify correctly the IRIS key filename in *definitions.json*
      - ```"LicenseKey": "ubuntu-sharding-iris.key"```


## Usage
The utility provisions as many cluster as there are subdirectories which are named **AWSn-description**. There are *4 clusters* here starting from cluster 2. Cluster n.1 is supposed to be your local development one that you can define in SAM by hand as an exercise.

### Provisioning
To provision the cloud clusters run the script
```
$ ./aws-provision.sh

This utility provisions 4 AWS clusters

Please provide the filename with the AWS credentials: ./aws.credentials

Credential provided in file:
--
[default]
aws_access_key_id = ASIARY6J4RI5HLBHARYO
aws_secret_access_key = c7JBdjG58R2kh2rOEfnIy1aL5/LoSZrt8dTDtx1s
aws_session_token = IQoJb3JpZ2luX2VjEJf//////////wEaCXVzLWVhc3QtMSJHMEUCIQCvYL0Kp4qkQ7mrKvNH/Uh/zba0aT+5jVIyQHgRVMmpJgIgAwtZoP9lZIxPo5YPcX7PTtV5TdcVSdnykaoXmexd/Igq/QEI7///////////ARACGgwxMjIyOTMwOTQ5NzAiDOji2xnARn9fLkBLRyrRATEz5luNc3ytM3J8/eZO3cjiofSVcBeorJLGDgrX+47CFPcGKCzK3/3Hyl+xBg0iMTLkvkHjEkmDKVhPcqMLbFoOFt8lqzG0Ap0b1TPczHYVZthkKbYqb30j/A8dk9haRSiUywgJYLX/3dWsR9Z35PUNYm8vFW0qrwvqeQiVODiRoZRPA0+2OJJ65jkJMCt48geD5DSFV1EhHB6n2mEio0HHHF7/OxbDGGZuGFypPufKDdOrEZyL6qYDQaCC00l6vQZWzdxBuAIVdjbi/5vr95pEMIOvxPYFOugBylsMgVJ6JJWJmq49szQBlIg+tJ2P07U2MT82WkHGzm3kTbcymcdMUZtrvX6Qglv4/BUcG7pTD7GpAHQvBk3wl2FzquTCnH0o8yOGBKcCwv3ZDyaGDPzy8/gKHO7hq1LnaPMy2Ye6GBtstO04PGWPE5ndwaYalrVuBZ/WMfZGVFzWg2vqyg+3CuK9+OnsE3dF96P+jy0jNhIyy1o0RgUlybA/DQ8MWrxdK6vMRFQ2/hfzXa9yzD6uY6s/zD3nrVJdzHm95TGnVhsApH0mHcRCMVqIbVQSDv6VYxv3urfazCMKf86FFfo68g==


--
overwrite ./AWS2-QA/aws.credentials? (y/n [n]) y
overwrite ./AWS3-UAT/aws.credentials? (y/n [n]) y
overwrite ./AWS4-PreProd/aws.credentials? (y/n [n]) y
overwrite ./AWS5-Prod/aws.credentials? (y/n [n]) y

...
```

The above process provisions the AWS infrastructure as in VPC, EC2 instances, storage, etc. in each region according to the definition or ```defaults.json``` in each subdirectory. At present the operation is serial for easier debugging, therefore, the time required is about 25 minutes for the infrastructure part and 15 to run up and configure all the instances.

### Verification
If you don't have access to the AWS portal or don't want to use it, you can quickly check if the nodes and the instances are up and OK via the ```icm inventory``` and ```icm ps``` commands that are wrapped for all the cluster in the following script    
```
$ ./aws-inventory.sh

***Directory and cluster AWS2-QA
Machine                        IP Address       DNS Name                                 Provider Region     Zone
-------                        ----------       --------                                 -------- ------     ----
luca-COMPUTE-QA-0001           54.67.40.202     ec2-54-67-40-202.us-west-1.compute.amazo AWS      us-west-1  c
luca-COMPUTE-QA-0002           54.219.144.230   ec2-54-219-144-230.us-west-1.compute.ama AWS      us-west-1  c
luca-DATA-QA-0001              3.101.63.99      ec2-3-101-63-99.us-west-1.compute.amazon AWS      us-west-1  c
luca-DATA-QA-0002              54.183.184.21    ec2-54-183-184-21.us-west-1.compute.amaz AWS      us-west-1  c
Machine                        IP Address       Container            Status   Health     Image
-------                        ----------       ---------            ------   ------     -----
luca-COMPUTE-QA-0002           54.219.144.230   iris                 Up       healthy    intersystems/iris:2020.3.0XDBC.132.0
luca-COMPUTE-QA-0001           54.67.40.202     iris                 Up       healthy    intersystems/iris:2020.3.0XDBC.132.0
luca-DATA-QA-0002              54.183.184.21    iris                 Up       healthy    intersystems/iris:2020.3.0XDBC.132.0
luca-DATA-QA-0001              3.101.63.99      iris                 Up       healthy    intersystems/iris:2020.3.0XDBC.132.0

***Directory and cluster AWS3-UAT
Machine                        IP Address       DNS Name                                 Provider Region     Zone
-------                        ----------       --------                                 -------- ------     ----
luca-COMPUTE-UAT-0001          3.12.36.232      ec2-3-12-36-232.us-east-2.compute.amazon AWS      us-east-2  a
luca-COMPUTE-UAT-0002          13.59.199.129    ec2-13-59-199-129.us-east-2.compute.amaz AWS      us-east-2  a
luca-COMPUTE-UAT-0003          3.135.192.222    ec2-3-135-192-222.us-east-2.compute.amaz AWS      us-east-2  a
luca-COMPUTE-UAT-0004          3.136.23.150     ec2-3-136-23-150.us-east-2.compute.amazo AWS      us-east-2  a
luca-DATA-UAT-0001             18.219.45.62     ec2-18-219-45-62.us-east-2.compute.amazo AWS      us-east-2  a
luca-DATA-UAT-0002             3.16.68.176      ec2-3-16-68-176.us-east-2.compute.amazon AWS      us-east-2  a
Machine                        IP Address       Container            Status   Health     Image
-------                        ----------       ---------            ------   ------     -----
luca-DATA-UAT-0002             3.16.68.176      iris                 Up       healthy    intersystems/iris:2020.3.0XDBC.132.0
luca-COMPUTE-UAT-0004          3.136.23.150     iris                 Up       healthy    intersystems/iris:2020.3.0XDBC.132.0
luca-COMPUTE-UAT-0002          13.59.199.129    iris                 Up       healthy    intersystems/iris:2020.3.0XDBC.132.0
luca-COMPUTE-UAT-0001          3.12.36.232      iris                 Up       healthy    intersystems/iris:2020.3.0XDBC.132.0
luca-COMPUTE-UAT-0003          3.135.192.222    iris                 Up       healthy    intersystems/iris:2020.3.0XDBC.132.0
luca-DATA-UAT-0001             18.219.45.62     iris                 Up       healthy    intersystems/iris:2020.3.0XDBC.132.0

...  
```  


## SAM configuration
After the above step has concluded, you can populate the local SAM instance with all the public DNS provided by AWS. To configure SAM automatically run  
```  
$ ./SAM-populate.sh
```  
SAM will monitor directly all your instances in all your clusters in the various AWS regions. That has the benefit of not having to swicth between AWS portal pages.   
Please not that we are able to monitor all those cloud instances on our local SAM instance because they have a *public DNS*. As described in the intro, this is OK for testing but probably not ideal for production environments.




To connect to the SAM UI point your browser to the following URL.  
You'll be asked for InterSystems IRIS credentials that you should know already
```
http://<host-name>:8080/api/sam/app/index.csp
```
## Let's stress it
If we want to run some stress-testing on a node to see how [SAM](https://github.com/intersystems-community/sam) displays information, we can quickly connect to an InterSystems IRIS session with the procedure described below.  

Chose a region or a cluster you want to connect to; let's pick the *pre-production* cluster, for example
```
$ cd AWS5-PreProd
```

Let's get to the ICM prompt so that we can run ICM commands that are cluster and security aware
```
$ ./icm.sh
```

Notice the new prompt below. You are now in an ICM container that is fully aware of the *pre-production* cluster (region, DNS, ssh keys, etc.).  
Let's find out the available nodes and instances (ICM instance placement strategy is that of one instance per node) with the **inventory** command
```
# icm inventory
Machine                        IP Address       DNS Name                                 Provider Region     Zone
-------                        ----------       --------                                 -------- ------     ----
luca-COMPUTE-PreProd-0001      18.157.159.72    ec2-18-157-159-72.eu-central-1.compute.a AWS      eu-central-1 c
luca-COMPUTE-PreProd-0002      18.157.177.209   ec2-18-157-177-209.eu-central-1.compute. AWS      eu-central-1 c
luca-COMPUTE-PreProd-0003      18.156.36.17     ec2-18-156-36-17.eu-central-1.compute.am AWS      eu-central-1 c
luca-COMPUTE-PreProd-0004      18.156.193.202   ec2-18-156-193-202.eu-central-1.compute. AWS      eu-central-1 c
luca-DATA-PreProd-0001         35.158.104.53    ec2-35-158-104-53.eu-central-1.compute.a AWS      eu-central-1 c
luca-DATA-PreProd-0002         3.122.99.43      ec2-3-122-99-43.eu-central-1.compute.ama AWS      eu-central-1 c
luca-DATA-PreProd-0003         3.121.211.145    ec2-3-121-211-145.eu-central-1.compute.a AWS      eu-central-1 c
luca-DATA-PreProd-0004         18.157.180.12    ec2-18-157-180-12.eu-central-1.compute.a AWS      eu-central-1 c
```

And finally let's obtain an interactive **session** into the InterSystems IRIS of our choice
```  
# icm session -interactive -machine luca-COMPUTE-PreProd-0001
Node: iris-luca-COMPUTE-PreProd-0001.weave.local, Instance: IRIS

DB>
```

And let's stress the system with a super-quick persistent array of 100M nodes
```
DB>for x=1:1:100000000 set ^message(x)="Hey world of InterSystems IRIS; this is cool! Hey SAM, Watch me! :-)"
```

Now, allow SAM to retrieve the monitoring information from the instances and check out the *compute* and the *data* nodes of this cluster:
- What differences do you see?
- What is getting stressed and where?

## Unprovision
To end it all and unprovision everything by deleting all the InterSystems IRIS instances, EC2 instances, security groups, VPCs and all, simply run  
```
$ ./aws-unprovision.sh
Do you wish to unprovision all clusters (y/n) y
...
```

## TODO
1. check if the _jq_ tool is installed & perhaps prompt for automatic installation (detecting Linux distro).
2. create a log file to more easily trace things vs scrolling the terminal ouput. 
3. parallelize cluster provisioning; #2 would becomes a requirement then.
  
---

Happy Monitoring! :-)



