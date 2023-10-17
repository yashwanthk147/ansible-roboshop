data "aws_caller_identity" "current" {}


data "aws_ami" "ami" {
  most_recent      = true
  name_regex       = "ansible-devops-practice"
  owners           = [data.aws_caller_identity.current.account_id]


}


#when do we use quotes in output blocks
#wen you have combi of strings and variables in a mesage that we are trying to print
//output "types" {
//  value = "Variable sample5 - ${var.sample5}, First value in list - ${var.sample6[0]}, Boolean Value of Map = ${var.sample7["boolean"]}"
//}

resource "aws_instance" "instance" {
    #count                    = length(var.instance)
    #for_each                 =  var.instance
    ami                      = data.aws_ami.ami.image_id
    instance_type            = var.instance_type
    vpc_security_group_ids   = [aws_security_group.allow_tls.id]
    tags = {
      Name             = "${var.component}-${var.env}"
    }
  
}

resource "null_resource" "provisioner" {
    provisioner "remote-exec" {
       connection {
         host = aws_instance.instance.public_ip
         user = "root"
         password = "DevOps321"
       }

       inline = [ 
         "ansible-pull -i localhost, -U https://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@github.com/yashwanthk147/ansible-roboshop.git roboshop.yml -e role_name=${var.component}"
       ]
      
    }
    
  
}


resource "aws_security_group" "allow_tls" {
  name        = "${var.component}-${var.env}-sg"
  description = "Allow TLS inbound traffic"

  ingress {
    description      = "TLS from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name             = "${var.component}-${var.env}-sg"
  }
}




resource "aws_route53_record" "record" {
    zone_id = "Z07897561J3VF42BTNNBR"
    name = "${var.component}-dev-devops.online"
    type = "A"
    ttl = 30
    records =  [aws_instance.instance.private_ip] 

}



variable "component" {}

variable "instance_type" {}


variable "env" {
    default = "dev"
  
}