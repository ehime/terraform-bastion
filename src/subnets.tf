/** internet access */
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

/** public subnet for the nat instance and the jumpbox */
resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${var.public_subnet_cidr}"
  availability_zone       = "${lookup(var.default_az, var.region)}"
  map_public_ip_on_launch = true
  depends_on              = ["aws_internet_gateway.default"]

  tags {
    Name = "public-net"
  }
}

/** private network for the Ehimeprefecture managed vms */
resource "aws_subnet" "ehime" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${var.ehime_subnet_cidr}"
  availability_zone       = "${lookup(var.default_az, var.region)}"
  map_public_ip_on_launch = false
  depends_on              = ["aws_instance.nat"]

  tags {
    Name = "ehime-net"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
}

resource "aws_route_table" "ehime" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = "${aws_instance.nat.id}"
  }

  tags {
    Name = "private-net"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "ehime" {
  subnet_id      = "${aws_subnet.ehime.id}"
  route_table_id = "${aws_route_table.ehime.id}"
}
