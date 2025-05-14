
resource "aws_route53_zone" "main" {
  name = "itiproject.site"
}


resource "aws_acm_certificate" "itiproject_cert" {
  domain_name               = "itiproject.site"
  validation_method         = "DNS"
  subject_alternative_names = var.subdomains

  tags = {
    Name = "itiproject-multi-cert"
  }
}


resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.itiproject_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 300
}


# resource "aws_acm_certificate_validation" "itiproject" {
#   certificate_arn         = aws_acm_certificate.itiproject_cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
# }
