output "vpc_id" {
    description = "vpc_id is"
    value = aws_vpc.pgagi_vpc.id
}

output "public_subnet" {
    description = "public subnets 1 is:"
    value = aws_subnet.pgagi_pubsub1.id
}

output "public_subnet2" {
    description = "public subnet 2 is:"
    value = aws_subnet.pgagi_pubsub2.id
}
output "private_subnet1" {
    description = "Private subnet 1 is: " 
    value =  aws_subnet.pgagi_prisub1.id
}
output "private_subnet2" {
    description = "Private subnet 2 is" 
    value = aws_subnet.pgagi_prisub2.id
}
output "internet_gateway" {
    description = "Internet gateway id is :"
    value = aws_internet_gateway.igw_gateway.id
}
output "nat_gateway" {
    description = "nat gateway id is :"
    value = aws_nat_gateway.nat_gateway.id
}
