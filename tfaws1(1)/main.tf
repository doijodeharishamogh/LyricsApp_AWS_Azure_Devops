resource "aws_instance" "my-test-instance-dino" {
  ami             = "ami-0dc34a024759117e0"
  instance_type   = "t2.micro"
  security_groups = ["devops_apps"]
  key_name = "amoghWin"
  user_data = <<-EOF
      #!/bin/bash
      sudo docker pull doijoy46/dotnet:v3
      sudo docker run --name test --rm -d -i -t -p 5000:5000 doijoy46/dotnet:v3
	EOF
  tags = {
    Name = "test-instance"
  }
}