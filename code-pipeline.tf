
resource "aws_s3_bucket" "codepipeline" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.appname}-codepipeline"
  acl    = "private"

  tags = {
    appname = var.appname
  }
}

##################################################
# BACKEND

resource "aws_codepipeline" "lambdas" {
  name     = "${var.appname}-lambdas"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        RepositoryName       = "${var.appname}-backend"
        BranchName           = "master"
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Build"
    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]
      configuration = {
        ProjectName = "${var.appname}-lambdas"
      }
    }
  }

  tags = {
    appname = var.appname
  }
}

resource "aws_codebuild_project" "lambdas" {
  name          = "${var.appname}-lambdas"
  description   = "Build lambdas for ${var.appname}"
  build_timeout = "5"
  service_role  = aws_iam_role.codepipeline.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:4.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type = "CODEPIPELINE"
  }

  tags = {
    appname = var.appname
  }
}

resource "aws_cloudwatch_event_rule" "lambdas_pipeline" {
  name          = "${var.appname}-lambdas-pipeline"
  event_pattern = <<PATTERN
{
  "source": [
    "aws.codecommit"
  ],
  "detail-type": [
    "CodeCommit Repository State Change"
  ],
  "resources": [
    "${aws_codecommit_repository.backend.arn}"
  ],
  "detail": {
    "event": [
      "referenceCreated",
      "referenceUpdated"
    ],
    "referenceType": [
      "branch"
    ],
    "referenceName": [
      "master"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "lambdas_pipeline" {
  rule     = aws_cloudwatch_event_rule.lambdas_pipeline.name
  arn      = aws_codepipeline.lambdas.arn
  role_arn = aws_iam_role.codepipeline.arn
}
