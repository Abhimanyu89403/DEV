variable "environment" {
    description = "Environment Name"
    type = string
}
variable "fe_port" {
    description = "port number also env variable"
    type = number
}

variable "be_port" {
    description = "be port number"
    type = number
}
variable "owner" {
    description = "Owner of the team"
    type = string
}
variable "team" {
    description = "which team the owner belongs to"
    type = string
}