import * as cdk from "aws-cdk-lib";
import { CoffeeMenuStack } from "../lib/coffee-menu-stack";

const app = new cdk.App();

new CoffeeMenuStack(app, "CoffeeMenuStack", {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  },
});
