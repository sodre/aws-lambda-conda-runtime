variable "asset_bucket" {
    type = object({
        id = string
    })
    description = "The asset bucket."
}

variable "environment" {
    type = string
    description = "environment.yml path"
}