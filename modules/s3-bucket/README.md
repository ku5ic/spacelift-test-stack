# s3-bucket

Minimal S3 bucket module, versioned and tagged. Exists so it can be registered in Spacelift's private Module Registry (see meta/modules_registry.tf) and consumed from a Module ID rather than a raw source path, to test that feature end to end.

## Usage

```hcl
module "example" {
  source  = "spacelift.io/<account>/s3-bucket/aws"
  version = "~> 1.0"

  bucket_name = "my-bucket"
  environment = "test"
}
```
