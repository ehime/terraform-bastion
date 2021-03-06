/** nat instance */
resource "aws_instance" "nat" {
  ami                                  = "${data.aws_ami.ubuntu.id}"
  availability_zone                    = "${lookup(var.default_az, var.region)}"
  instance_type                        = "t2.micro"
  instance_initiated_shutdown_behavior = "terminate"

  vpc_security_group_ids = [
    "${aws_security_group.ehime.id}",
    "${aws_security_group.vpc_nat.id}",
    "${aws_security_group.ssh.id}",
  ]

  subnet_id                   = "${aws_subnet.public.id}"
  associate_public_ip_address = true
  source_dest_check           = false
  key_name                    = "${aws_key_pair.deployment.key_name}"

  provisioner "remote-exec" {
    connection {
      user        = "ubuntu"
      timeout     = "5m"
      private_key = "${file("ssh/deployment.pem")}"
    }

    inline = [
      "sudo apt -y update",
      "sudo apt -y upgrade",
      "sudo iptables -t nat -A POSTROUTING -j MASQUERADE",
      "echo 1 |sudo tee /proc/sys/net/ipv4/conf/all/forwarding >/dev/null",
    ]
  }

  /** execute the remote script */
  provisioner "remote-exec" {
    connection {
      user        = "ubuntu"
      host        = "${aws_instance.nat.public_dns}"
      timeout     = "25m"
      private_key = "${file("ssh/deployment.pem")}"
    }

    inline = [
      "chmod +x destroy.sh",
      "echo ./destroy.sh ${var.death_clock}",
    ]
  }

  tags {
    Name = "VPC NAT"
  }
}

resource "aws_eip" "nat" {
  instance = "${aws_instance.nat.id}"
  vpc      = true
}
