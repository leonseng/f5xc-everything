terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "~> 0.11"
    }

    restful = {
      source  = "magodo/restful"
      version = ">= 0.16.1"
    }
  }
}