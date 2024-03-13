 # Create an EBS volume
resource "aws_ebs_volume" "cdci_ebs_volume" {
  availability_zone = "us-west-2a"
  size              = 10
}

# Attach the EBS volume to an EC2 instance
resource "aws_volume_attachment" "example" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.cdci_ebs_volume.id
  instance_id = "i-0123456789abcdef"
}
