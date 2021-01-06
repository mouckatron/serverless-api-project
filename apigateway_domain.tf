
resource "aws_api_gateway_domain_name" "api" {
  regional_certificate_arn = aws_acm_certificate_validation.api.certificate_arn
  domain_name              = local.domain

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    appname = var.appname
  }
}

resource "aws_api_gateway_base_path_mapping" "api" {
  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.production.stage_name
  domain_name = aws_api_gateway_domain_name.api.domain_name
}

resource "aws_route53_record" "api" {
  name    = aws_api_gateway_domain_name.api.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.root_domain.id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.api.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api.regional_zone_id
  }
}

resource "aws_acm_certificate" "api" {
  domain_name       = local.domain
  validation_method = "DNS"

  tags = {
    appname = var.appname
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "certvalidation" {
  for_each = {
    for dvo in aws_acm_certificate.api.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.root_domain.zone_id
}

resource "aws_acm_certificate_validation" "api" {
  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [for record in aws_route53_record.certvalidation : record.fqdn]
}
